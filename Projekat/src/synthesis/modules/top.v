module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input [1:0] kbd,
    input [2:0] btn,
    input [9:0] sw,
    output [13:0] mnt,
    output [9:0] led,
    output [27:0] hex
);

    wire clk_out;
    
    clk_div #(
        .DIVISOR(DIVISOR)
    ) clk_div_inst (
        .clk(clk),
        .rst_n(sw[9]),
        .out(clk_out)
    );

    wire mem_we;
    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [DATA_WIDTH-1:0] mem_data_in;
    wire [DATA_WIDTH-1:0] mem_data_out;

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memory_inst (
        .clk(clk_out),
        .we(mem_we),
        .addr(mem_addr),
        .data(mem_data_in),
        .out(mem_data_out)
    );

    wire [ADDR_WIDTH-1:0] pc_out;
    wire [DATA_WIDTH-1:0] sp_out;
    wire cpu_control;
    wire [5:0] scan_num;
    wire [15:0] inp;
    wire scan_status;
    wire [15:0] cpu_out;

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_inst (
        .clk(clk_out),
        .rst_n(sw[9]),
        .mem(mem_data_out),
        .status(scan_status),
        .we(mem_we),
        .addr(mem_addr),
        .data(mem_data_in),
        .pc(pc_out),
        .sp(sp_out),
        .control(cpu_control),
        .out(cpu_out),
        .in(inp)
    );

    assign led[4:0] = cpu_out;
    assign led[5] = scan_status;
    assign led[9:6] = 4'b0000;

    wire ps2_code_valid;
    wire [15:0] ps2_code;

    ps2 ps2_inst (
        .clk(clk),
        .rst_n(sw[9]),
        .ps2_clk(kbd[0]),
        .ps2_data(kbd[1]),
        .code(ps2_code)
    );

    scan_codes scan_codes_inst (
        .clk(clk_out),
        .rst_n(sw[9]),
        .code(ps2_code),
        .control(cpu_control),
        .num(inp[3:0]),
        .status(scan_status)
    );



    wire [3:0] bcd_sp_ones;
    wire [3:0] bcd_sp_tens;

    bcd bcd_sp_inst (
        .in(sp_out[5:0]),
        .ones(bcd_sp_ones),
        .tens(bcd_sp_tens)
    );

    ssd ssd_sp_ones_inst (
        .in(bcd_sp_ones),
        .out(hex[20:14])
    );

    ssd ssd_sp_tens_inst (
        .in(bcd_sp_tens),
        .out(hex[27:21])
    );

    wire [23:0] color_code;

    color_codes color_codes_inst (
        .num(cpu_out[5:0]),
        .code(color_code)
    );

    wire hsync, vsync;
    wire [3:0] vga_red, vga_green, vga_blue;

    vga vga_inst (
        .clk(clk_out),
        .rst_n(sw[9]),
        .code(color_code),
        .hsync(hsync),
        .vsync(vsync),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );

    assign mnt[13] = hsync;
    assign mnt[12] = vsync;
    assign mnt[11:8] = vga_red;
    assign mnt[7:4] = vga_green;
    assign mnt[3:0] = vga_blue;

endmodule


