`timescale 1ns/1ps

module testbench;

    //---------------------------------
    // Импорт паккейджа тестирования
    //---------------------------------

    import test_pkg::*;


    //---------------------------------
    // Сигналы
    //---------------------------------

    logic        clk;
    logic        aresetn;


    //---------------------------------
    // Интерфейс
    //---------------------------------

    axis_intf intf_master (clk, aresetn);
    axis_intf intf_slave  (clk, aresetn);


    //---------------------------------
    // Модуль для тестирования
    //---------------------------------

    pow DUT(
        .clk      ( clk                 ),
        .aresetn  ( aresetn             ),
        .s_tvalid ( intf_master.tvalid  ),
        .s_tready ( intf_master.tready  ),
        .s_tdata  ( intf_master.tdata   ),
        .s_tid    ( intf_master.tid     ),
        .s_tlast  ( intf_master.tlast   ),
        .m_tvalid ( intf_slave.tvalid   ),
        .m_tready ( intf_slave.tready   ),
        .m_tdata  ( intf_slave.tdata    ),
        .m_tid    ( intf_slave.tid      ),
        .m_tlast  ( intf_slave.tlast    )
    );


    //---------------------------------
    // Переменные тестирования
    //---------------------------------

    // Период тактового сигнала
    parameter CLK_PERIOD = 10;


    //---------------------------------
    // Общие методы
    //---------------------------------

    // Генерация сигнала сброса
    task reset();
        aresetn <= 0;
        #(100*CLK_PERIOD);
        aresetn <= 1;
    endtask


    // TODO:
    // Создайте класс драйвера мастера
    // (отнаследуйтесь от 'master_driver_base'),
    // который в конце каждого пакета делает
    // дополнительную задержку в 100 тактов.
    // make EXAMPLE=02_pow SIM_OPTS=-gui WITH_PKG=1

    class driver_delay extends master_driver_base;
        virtual task drive_master(packet p);
            super.drive_master(p);
            if (p.tlast) begin
                repeat(100) @(posedge clk); 
            end
        endtask
    endclass

    // TODO:
    // Создайте тестовый сценарий, в котором замените
    // базовый драйвер мастера на новый, который создали.
    // Обратите внимание на то, что при переопределении
    // драйвера поля нового драйвера необходимо также
    // проинициализировать.

    class test_delay extends test_base;
        function new (
            virtual axis_intf vif_master,
            virtual axis_intf vif_slave
        );
            driver_delay driver_delay = new();
            super.new(vif_master, vif_slave, driver_delay);
        endfunction
    endclass

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

    // TODO:
    // Запустите новый тестовый сценарий

    initial begin
        test_delay test;
        test = new(intf_master, intf_slave);
        fork
            reset();
            test.run();
        join_none
        repeat(1000) @(posedge clk);
        // Сброс в середине теста
        reset();
    end

endmodule