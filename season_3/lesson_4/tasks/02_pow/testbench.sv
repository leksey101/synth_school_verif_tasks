`timescale 1ns/1ps

module testbench;


    //---------------------------------
    // Сигналы
    //---------------------------------

    logic        clk;
    logic        aresetn;

    logic        s_tvalid;
    logic        s_tready;
    logic [31:0] s_tdata;
    logic        s_tid;
    logic        s_tlast;

    logic        m_tvalid;
    logic        m_tready;
    logic [31:0] m_tdata;
    logic        m_tid;
    logic        m_tlast;


    //---------------------------------
    // Модуль для тестирования
    //---------------------------------

    pow DUT(
        .clk      ( clk       ),
        .aresetn  ( aresetn   ),
        .s_tvalid ( s_tvalid  ),
        .s_tready ( s_tready  ),
        .s_tdata  ( s_tdata   ),
        .s_tid    ( s_tid     ),
        .s_tlast  ( s_tlast   ),
        .m_tvalid ( m_tvalid  ),
        .m_tready ( m_tready  ),
        .m_tdata  ( m_tdata   ),
        .m_tid    ( m_tid     ),
        .m_tlast  ( m_tlast   )
    );


    //---------------------------------
    // Переменные тестирования
    //---------------------------------

    // Период тактового сигнала
    parameter CLK_PERIOD = 10;

    // Пакет и mailbox'ы
    class packet;
        rand int          delay;
        rand logic [31:0] tdata;
        rand logic        tid;
        rand logic        tlast;
    endclass

    mailbox#(packet) gen2drv = new();
    mailbox#(packet) in_mbx  = new();
    mailbox#(packet) out_mbx = new();


    //---------------------------------
    // Методы
    //---------------------------------

    // Генерация сигнала сброса
    task reset();
        aresetn <= 0;
        #(CLK_PERIOD);
        aresetn <= 1;
    endtask

    // Таймаут теста
    task timeout(int timeout_cycles = 100000);
        repeat(timeout_cycles) @(posedge clk);
        $error("Test timeout!");
        $finish();
    endtask

    // Master
    task gen_master(
        int size_min   = 1,
        int size_max   = 10,
        int delay_min  = 0,
        int delay_max  = 10
    );
        packet p;
        int size;
        void'(std::randomize(size) with {size inside {[size_min:size_max]};});
        for(int i = 0; i < size; i = i + 1) begin
            p = new();
            if( !p.randomize() with {
                p.delay inside {[delay_min:delay_max]};
                p.tlast == (i == size - 1);
            } ) begin
                $error("Can't randomize packet!");
                $finish();
            end
            gen2drv.put(p);
        end
    endtask

    // TODO:
    // Разбейте количество пакетов пополам и для
    // второй половины сгенерируйте пакеты с задержкой
    // в 5 раз больше.
    // Сохраните стабильность рандомизации для первой
    // половины
    // make EXAMPLE=02_pow SIM_OPTS=-gui
    task do_master_gen(
        int pkt_amount = 100,
        int size_min   = 1,
        int size_max   = 10,
        int delay_min  = 0,
        int delay_max  = 10
    );
        repeat(pkt_amount/2) begin
            gen_master(size_min, size_max, delay_min, delay_max);
        end

        repeat(pkt_amount/2) begin
            gen_master(size_min, size_max, delay_min*5, delay_max*5);
        end
    endtask

    task reset_master();
        wait(~aresetn);
        s_tvalid <= 0;
        s_tdata  <= 0;
        s_tid    <= 0;
        wait(aresetn);
    endtask

    task drive_master(packet p);
        repeat(p.delay) @(posedge clk);
        s_tvalid <= 1;
        s_tdata  <= p.tdata;
        s_tid    <= p.tid;
        s_tlast  <= p.tlast;
        do begin
            @(posedge clk);
        end
        while(~s_tready);
        s_tvalid <= 0;
        s_tlast  <= 0;
    endtask

    task do_master_drive();
        packet p;
        reset_master();
        forever begin
            @(posedge clk);
            fork
                forever begin
                    gen2drv.get(p);
                    drive_master(p);
                end
            join_none
            reset_master();
            disable fork;
        end
    endtask

    task monitor_master();
        packet p;
        @(posedge clk);
        if( s_tvalid & s_tready ) begin
            p = new();
            p.tdata  = s_tdata;
            p.tid    = s_tid;
            p.tlast  = s_tlast;
            in_mbx.put(p);
        end
    endtask

    task do_master_monitor();
        forever begin
            wait(aresetn);
            fork
                forever begin
                    monitor_master();
                end
            join_none
            wait(~aresetn);
            disable fork;
        end
    endtask

    // Master
    task master(        
        int gen_pkt_amount = 100,
        int gen_size_min   = 1,
        int gen_size_max   = 10,
        int gen_delay_min  = 0,
        int gen_delay_max  = 10
    );
        fork
            do_master_gen(gen_pkt_amount, gen_size_min, gen_size_max, gen_delay_min, gen_delay_max);
            do_master_drive();
            do_master_monitor();
        join
    endtask

    // Slave
    task reset_slave();
        wait(~aresetn);
        m_tready <= 0;
        wait(aresetn);
    endtask

    task drive_slave(
        int delay_min  = 0,
        int delay_max  = 10
    );
        int delay;
        void'(std::randomize(delay) with {delay inside {[delay_min:delay_max]};});
        repeat(delay) @(posedge clk);
        m_tready <= 1;
        @(posedge clk);
        m_tready <= 0;
    endtask

    task do_slave_drive(
        int delay_min  = 0,
        int delay_max  = 10
    );
        reset_slave();
        forever begin
            @(posedge clk);
            fork
                forever begin
                    drive_slave(delay_min, delay_max);
                end
            join_none
            reset_slave();
            disable fork;
        end
    endtask

    task monitor_slave();
        packet p;
        @(posedge clk);
        if( m_tvalid & m_tready ) begin
            p = new();
            p.tdata  = m_tdata;
            p.tid    = m_tid;
            p.tlast  = m_tlast;
            out_mbx.put(p);
        end
    endtask

    task do_slave_monitor();
        forever begin
            wait(aresetn);
            fork
                forever begin
                    monitor_slave();
                end
            join_none
            wait(~aresetn);
            disable fork;
        end
    endtask

    // Slave
    task slave(
        int delay_min  = 0,
        int delay_max  = 10
    );
        fork
            do_slave_drive(delay_min, delay_max);
            do_slave_monitor();
        join
    endtask

    // Проверка
    task check(packet in, packet out);
        if( in.tid !== out.tid ) begin
            $error("%0t Invalid TID: Real: %h, Expected: %h",
                $time(), out.tid, in.tid);
        end
        if( out.tdata !== in.tdata ** 5 ) begin
            $error("%0t Invalid TDATA: Real: %0d, Expected: %0d ^ 5 = %0d",
                $time(), out.tdata, in.tdata, in.tdata ** 5);
        end
        if( in.tlast !== out.tlast ) begin
            $error("%0t Invalid TLAST: Real: %1b, Expected: %1b",
                $time(), out.tlast, in.tlast);
        end
    endtask

    task automatic do_check(ref bit done, input int pkt_amount = 1);
        int cnt;
        packet in_p, out_p;
        forever begin
            wait(aresetn);
            fork
                forever begin
                    in_mbx.get(in_p);
                    out_mbx.get(out_p);
                    check(in_p, out_p);
                    cnt = cnt + out_p.tlast;
                    if( cnt == pkt_amount ) begin
                        break;
                    end
                end
                begin
                    wait(~aresetn);
                end
            join_any
            disable fork;
            // Если достигли нужного количества пакетов,
            // то выходим из бесконечного цикла и выставляем
            // флаг завершения
            if( cnt == pkt_amount ) begin
                done = 1;
                break;
            end
            // Иначе пришел сигнал сброса. Очищаем mailbox
            // от входящих транзакций, т.к все они будут
            // "выкинуты" из конвейера при приходе сигнала сброса
            while(in_mbx.try_get(in_p)) cnt = cnt + in_p.tlast;
        end
    endtask

    task automatic error_checker(ref bit done, input int pkt_amount = 1);
        do_check(done, pkt_amount);
    endtask


    //---------------------------------
    // Выполнение
    //---------------------------------

    // Генерация тактового сигнала
    initial begin
        clk <= 0;
        forever begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end

    task test(
            int gen_pkt_amount   = 100,    // количество пакетов 
            int gen_size_min     = 1,      // мин. размер пакета
            int gen_size_max     = 10,     // макс. размер пакета
            int gen_delay_min    = 0,      // мин. задержка между транзакциями
            int gen_delay_max    = 10,     // макс. задержка между транзакциями
            int slave_delay_min  = 0,      // минимальная задержка для slave
            int slave_delay_max  = 10,     // максимальная задержка для slave
            int timeout_cycles   = 100000  // таймаут теста
    );
        bit done;
        fork
            master       (gen_pkt_amount, gen_size_min, gen_size_max, gen_delay_min, gen_delay_max);
            slave        (slave_delay_min, slave_delay_max);
            error_checker(done, gen_pkt_amount);
            timeout      (timeout_cycles);
        join_none
        wait(done);
        $display("Test was finished!");
        $finish();
    endtask

    initial begin
        bit done;
        fork
            reset();
            test();
        join_none
        repeat(100) @(posedge clk);
        // Сброс в середине теста
        reset();
    end

endmodule
