// 1-bit full adder
// sum  = a XOR b XOR cin
// cout = 1 when at least two of the three inputs are 1
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
