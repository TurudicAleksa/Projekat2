module cpu #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 6
) (
 input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem,
    input [DATA_WIDTH-1:0] in,
    input control,
    output we,
    output [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [DATA_WIDTH-1:0] sp,
    output status
);
    register #(6) pc_reg ();
    register #(6) sp_reg ();
    register #(32) ir_reg ();
    register #(6) mar_reg ();
    register #(16) mdr_reg ();
    register #(16) acc_reg ();

    


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            
        end
        else begin
            
        end
    end

endmodule