module testbench;

    // Тактовый сигнал и сигнал сброса
    logic clk;
    logic aresetn;

    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;

    //intf intf (clk, aresetn);

    import package_cover::*;

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

    class_cover cg = new();

    initial begin
        forever begin
            @(posedge clk);
            cg.sum_cg.sample(a,b);
        end
    end

endmodule
