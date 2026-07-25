module bcd(
    input [5:0] in,
    output [3:0] ones,
    output [3:0] tens
);

wire [3:0] ones_wire= in % 10;
wire [3:0] tens_wire= in / 10 % 10;

endmodule
