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
    // Создайте класс драйвера слейва
    // (отнаследуйтесь от 'slave_driver_base'),
    // который c вероятностью в 2% "зависает"
    // (перестает генерировать ready) на 500
    // тактов
    // make EXAMPLE=03_pow SIM_OPTS=-gui WITH_PKG=1

    class lag_driver_slave extends slave_driver_base;
        virtual task drive_slave();
            super.drive_slave();
            randcase
                1:  begin 
                    repeat (500) @(posedge clk);
                end
                49: ;
            endcase
        endtask
    endclass

    class lag_driver_master extends master_driver_base;
        virtual task drive_master(packet p);
            super.drive_master(p);
            randcase
                1:  begin 
                    repeat (500) @(posedge clk);
                end
                49: ;
            endcase
        endtask
    endclass 

    // TODO:
    // Создайте тестовый сценарий, в котором замените
    // базовый драйвер слейва на новый, который создали.
    // Обратите внимание на то, что при переопределении
    // драйвера поля нового драйвера необходимо также
    // проинициализировать.

    class lag_test_base extends test_base;
        function new (
            virtual axis_intf vif_master,
            virtual axis_intf vif_slave
        );
            lag_driver_slave driver_lag_s = new();
            lag_driver_master driver_lag_m = new();
            super.new(vif_master, vif_slave, driver_lag_s, driver_lag_m);
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
        lag_test_base test;
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