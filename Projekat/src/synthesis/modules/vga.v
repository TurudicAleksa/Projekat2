module vga(
    input clk,
    input rst_n,
    input [23:0] code,
    output hsync,
    output vsync,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue
);

    reg [10:0] x_reg;
    reg [9:0] y_reg;

    localparam DISPLAY_X = 800;
    localparam TOTAL_X   = 1056;
    localparam SYNC_START_X = 856; 
    localparam SYNC_END_X   = 976;
    localparam HALF_POINT = 400; 

    localparam DISPLAY_Y = 600;
    localparam TOTAL_Y   = 666;
    localparam SYNC_START_Y = 637; 
    localparam SYNC_END_Y   = 643;

    wire display_flag = (x_reg < DISPLAY_X && y_reg < DISPLAY_Y);

    assign hsync = (x_reg >= SYNC_START_X && x_reg < SYNC_END_X) ? 1'b0 : 1'b1;
    assign vsync = (y_reg >= SYNC_START_Y && y_reg < SYNC_END_Y) ? 1'b0 : 1'b1;

    assign {red, green, blue} = (display_flag) ? ((x_reg < HALF_POINT) ? code[23:12] : code[11:0]) : 12'h000;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            x_reg <= 0;
            y_reg <= 0;
        end else begin
            if (x_reg == TOTAL_X - 1) begin
                x_reg <= 0;
                if (y_reg == TOTAL_Y - 1)
                    y_reg <= 0;
                else
                    y_reg <= y_reg + 1;
            end else begin
                x_reg <= x_reg + 1;
            end
        end
    end

endmodule