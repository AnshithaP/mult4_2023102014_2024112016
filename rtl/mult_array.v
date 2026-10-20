// 4-bit x 4-bit unsigned array multiplier, 8-bit registered product.
//
// Pipeline:  a, b --> input registers (a_r, b_r) --> array (16 AND + 12 FA) --> output register p
// Latency = 2 clock cycles. Throughput = 1 result per cycle.
// 16 flip-flops in total: 4 (a_r) + 4 (b_r) + 8 (p).
//
// Wiring follows the "Exact connections" table in Section 2 of the assignment.
// The multiplication operator is not used anywhere in this file.
module mult_array (
    input  wire       clk,
    input  wire       rst_n,   // asynchronous, active-low reset
    input  wire [3:0] a,       // multiplicand
    input  wire [3:0] b,       // multiplier
    output reg  [7:0] p        // product a x b, registered
);

    // ------------------------------------------------------------
    // Input registers
    // ------------------------------------------------------------
    reg [3:0] a_r, b_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r <= 4'd0;
            b_r <= 4'd0;
        end else begin
            a_r <= a;
            b_r <= b;
        end
    end

    // ------------------------------------------------------------
    // Partial products: ppi[j] = a[j] AND b[i]  (16 AND gates)
    // ------------------------------------------------------------
    wire [3:0] pp0 = a_r & {4{b_r[0]}};
    wire [3:0] pp1 = a_r & {4{b_r[1]}};
    wire [3:0] pp2 = a_r & {4{b_r[2]}};
    wire [3:0] pp3 = a_r & {4{b_r[3]}};

    // ------------------------------------------------------------
    // Row 0: AND gates only. p[0] = pp0[0]; upper 3 bits passed down.
    // ------------------------------------------------------------
    wire [3:0] r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

    // Sum and carry wires for rows 1-3.
    // c1[j] is the carry INTO full adder j of row 1; c1[4] is the row's carry out.
    wire [3:0] s1, s2, s3;
    wire [4:0] c1, c2, c3;

    assign c1[0] = 1'b0;
    assign c2[0] = 1'b0;
    assign c3[0] = 1'b0;

    genvar j;
    generate
        // Row 1: adds pp1 to r0 (4 full adders)
        for (j = 0; j < 4; j = j + 1) begin : row1
            full_adder fa (.a(pp1[j]), .b(r0[j]), .cin(c1[j]),
                           .sum(s1[j]), .cout(c1[j+1]));
        end
    endgenerate

    wire [3:0] r1 = {c1[4], s1[3], s1[2], s1[1]};

    generate
        // Row 2: adds pp2 to r1 (4 full adders)
        for (j = 0; j < 4; j = j + 1) begin : row2
            full_adder fa (.a(pp2[j]), .b(r1[j]), .cin(c2[j]),
                           .sum(s2[j]), .cout(c2[j+1]));
        end
    endgenerate

    wire [3:0] r2 = {c2[4], s2[3], s2[2], s2[1]};

    generate
        // Row 3: adds pp3 to r2 (4 full adders)
        for (j = 0; j < 4; j = j + 1) begin : row3
            full_adder fa (.a(pp3[j]), .b(r2[j]), .cin(c3[j]),
                           .sum(s3[j]), .cout(c3[j+1]));
        end
    endgenerate

    // ------------------------------------------------------------
    // Final product bits
    // p[0] = pp0[0], p[1] = s1[0], p[2] = s2[0], p[3] = s3[0],
    // p[7:4] = {c3[4], s3[3], s3[2], s3[1]}
    // ------------------------------------------------------------
    wire [7:0] prod = {c3[4], s3[3], s3[2], s3[1], s3[0], s2[0], s1[0], pp0[0]};

    // ------------------------------------------------------------
    // Output register
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p <= 8'd0;
        else
            p <= prod;
    end

endmodule
