// Exhaustive self-checking testbench for mult_array.
// - 10 ns clock, rst_n held low for the first 2 cycles
// - applies all 256 (a, b) combinations
// - waits the 2-cycle latency, then compares p with a * b
// - prints every mismatch and one PASS/FAIL summary line
// - writes mult.vcd
`timescale 1ns/1ps

module tb_mult;

    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    reg  [3:0] a     = 4'd0;
    reg  [3:0] b     = 4'd0;
    wire [7:0] p;

    reg  [7:0] expected;
    integer    i, k;
    integer    errors  = 0;
    integer    checked = 0;

    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // 10 ns clock period (rising edges at 5, 15, 25, ... ns)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        // Hold reset low for the first 2 clock cycles (0-20 ns)
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Inputs change on falling edges so they are stable at each rising edge
        for (i = 0; i < 16; i = i + 1) begin
            for (k = 0; k < 16; k = k + 1) begin
                a        = i;
                b        = k;
                expected = i * k;          // '*' is allowed in the testbench only

                @(posedge clk);            // edge 1: a, b captured into input registers
                @(posedge clk);            // edge 2: product captured into p
                @(negedge clk);            // half a cycle later: p is settled, check it

                if (p !== expected) begin
                    $display("MISMATCH at %0t ns: a=%0d b=%0d expected=%0d got=%0d",
                             $time, a, b, expected, p);
                    errors = errors + 1;
                end
                checked = checked + 1;
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", checked);
        else
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);

        $finish;
    end

endmodule
