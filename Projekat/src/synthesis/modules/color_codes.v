module color_codes (
    input [5:0] num,
    output reg [23:0] code
);
    wire [3:0] wire_ones;
    wire [3:0] wire_tens;
    bcd bcd_module (num, wire_ones, wire_tens);
    
    reg [11:0] ones_color;
    reg [11:0] tens_color;

    always @(*) begin
        ones_color = 12'h000;
        tens_color = 12'h000;

        case (wire_ones)
            4'd0: ones_color = 12'h000; 
            4'd1: ones_color = 12'hF00; 
            4'd2: ones_color = 12'hF80; 
            4'd3: ones_color = 12'hFF0; 
            4'd4: ones_color = 12'h0F0; 
            4'd5: ones_color = 12'h0FF; 
            4'd6: ones_color = 12'h08F; 
            4'd7: ones_color = 12'h00F; 
            4'd8: ones_color = 12'hF0F; 
            4'd9: ones_color = 12'hFFF; 
            default: ones_color = 12'h123;
        endcase

        case (wire_tens)
            4'd0: tens_color = 12'h000; 
            4'd1: tens_color = 12'hF00; 
            4'd2: tens_color = 12'hF80; 
            4'd3: tens_color = 12'hFF0; 
            4'd4: tens_color = 12'h0F0; 
            4'd5: tens_color = 12'h0FF; 
            4'd6: tens_color = 12'h08F; 
            4'd7: tens_color = 12'h00F; 
            4'd8: tens_color = 12'hF0F; 
            4'd9: tens_color = 12'hFFF;
            default: tens_color = 12'h123;
        endcase

        code = {tens_color, ones_color};
    end
endmodule