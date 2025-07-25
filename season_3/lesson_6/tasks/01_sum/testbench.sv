module testbench;

    // Тактовый сигнал и сигнал сброса
    logic clk;
    logic aresetn;

    // Остальные сигналы
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;

    sum DUT(
        .clk     ( clk     ),
        .aresetn ( aresetn ),
        .a       ( a       ),
        .b       ( b       ),
        .c       ( c       )
    );

    `include "generator.svh"

    // TODO:
    // В рамках симуляции значения 'a' и 'b'
    // генерируются согласно некоторым правилам.
    // Напишите модель покрытия, при помощи
    // которой определите, какие значения
    // принимают переменные 'a' и 'b'.
    // make EXAMPLE=01_sum SIM_OPTS="-gui -sv_seed 12345"

    covergroup sum_cg @(posedge clk);
        // Пишите здесь
        // ...
        a_cp: coverpoint a {
            bins a1 [256] = {[0:255]};
        }

        b_cp: coverpoint b {
            bins b1 [256] = {[0:255]};
        }
    endgroup

    sum_cg cg = new();

endmodule
