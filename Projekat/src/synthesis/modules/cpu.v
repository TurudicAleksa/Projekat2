module cpu #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 6
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] mem,
    input [DATA_WIDTH-1:0] in,
    output reg status,
    input control,
    output we,
    output [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] out,
    output [ADDR_WIDTH-1:0] pc,
    output [DATA_WIDTH-1:0] sp,
    output [7:0] test_state_machine
);


    
    reg pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il; 
    reg [ADDR_WIDTH-1:0] pc_in;
    wire [ADDR_WIDTH-1:0] pc_out;
    register #(ADDR_WIDTH) pc_reg (.clk(clk), .rst_n(rst_n), .cl(pc_cl), .ld(pc_ld), .in(pc_in), .inc(pc_inc), .dec(pc_dec), .sr(pc_sr), .ir(pc_ir), .sl(pc_sl), .il(pc_ir), .out(pc_out));
    assign pc = pc_out;

    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il; 
    reg [ADDR_WIDTH-1:0] sp_in;
    wire [ADDR_WIDTH-1:0] sp_out;
    register #(ADDR_WIDTH) sp_reg (.clk(clk), .rst_n(rst_n), .cl(sp_cl), .ld(sp_ld), .in(sp_in), .inc(sp_inc), .dec(sp_dec), .sr(sp_sr), .ir(sp_ir), .sl(sp_sl), .il(sp_il), .out(sp_out));
    assign sp = sp_out;

    reg ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il; 
    reg [31:0] ir_in;
    wire [31:0] ir_out;
    register #(32) ir_reg (.clk(clk), .rst_n(rst_n), .cl(ir_cl), .ld(ir_ld), .in(ir_in), .inc(ir_inc), .dec(ir_dec), .sr(ir_sr), .ir(ir_ir), .sl(ir_sl), .il(ir_il), .out(ir_out));
    
    reg mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il; 
    reg [ADDR_WIDTH-1:0] mar_in;
    wire [ADDR_WIDTH-1:0] mar_out;
    register #(ADDR_WIDTH) mar_reg (.clk(clk), .rst_n(rst_n), .cl(mar_cl), .ld(mar_ld), .in(mar_in), .inc(mar_inc), .dec(mar_dec), .sr(mar_sr), .ir(mar_ir), .sl(mar_sl), .il(mar_il), .out(mar_out));
    assign addr = mar_out;

    reg mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il; 
    wire [DATA_WIDTH-1:0] mdr_in;
    wire [DATA_WIDTH-1:0] mdr_out;
    register #(DATA_WIDTH) mdr_reg (.clk(clk), .rst_n(rst_n), .cl(mdr_cl), .ld(mdr_ld), .in(mem), .inc(mdr_inc), .dec(mdr_dec), .sr(mdr_sr), .ir(mdr_ir), .sl(mdr_sl), .il(mdr_il), .out(mdr_out));

    reg acc_cl, acc_ld, acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il; 
    reg [DATA_WIDTH-1:0] acc_in;
    wire [DATA_WIDTH-1:0] acc_out;
    register #(DATA_WIDTH) acc_reg (.clk(clk), .rst_n(rst_n), .cl(acc_cl), .ld(acc_ld), .in(acc_in), .inc(acc_inc), .dec(acc_dec), .sr(acc_sr), .ir(acc_ir), .sl(acc_sl), .il(acc_il), .out(acc_out));

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_MUL = 3'b010;

    reg [2:0] alu_oc_reg, alu_oc_next;
    reg [DATA_WIDTH-1:0] alu_a_reg, alu_a_next;
    reg [DATA_WIDTH-1:0] alu_b_reg, alu_b_next;
    wire [DATA_WIDTH-1:0] alu_f;

    alu#(DATA_WIDTH) alu_inst(.oc(alu_oc_reg), .a(alu_a_reg), .b(alu_b_reg), .f(alu_f));

    reg we_reg, we_next;
    reg [DATA_WIDTH-1:0] in_reg, in_next;
    reg[DATA_WIDTH-1:0] out_reg, out_next;

    assign we = we_reg;
    //assign in = in_reg;
    assign out = out_reg;

    reg[8:0] state_reg;
    reg[8:0] state_next;

    reg[3:0] opcode;
    reg[2:0] x_reg;
    reg[2:0] y_reg;
    reg[2:0] z_reg;
    reg x_adr, y_adr, z_adr;
    
    reg[3:0] xrez, yrez, zrez;
    

    reg[3:0] xreg, yreg, zreg;
    reg[3:0] xnext, ynext, znext;


    localparam [3:0]
            MOV = 4'b0000,
            ADD = 4'b0001,
            SUB = 4'b0010,
            MUL = 4'b0011,
            DIV = 4'b0100,
            IN = 4'b0111,
            OUT = 4'b1000,
            STOP = 4'b1111
            ;

    localparam [8:0]
            START = 8'd0,
            INFETCH1 = 8'd1,
            INFETCH2 = 8'd2,
            INFETCH3 = 8'd3,
            INFETCH4 = 8'd4,
            INDECODE1=8'd5,
            STOPPED=8'd6,
            MOV1=8'd7,
            ADD1=8'd8,
            SUB1=8'd9,
            MUL1=8'd10,
            IN1=8'd11,
            OUT1=8'd12,
            STOP1=8'd13,
            XIND=8'd14,
            YIND=8'd15,
            ZIND=8'd16,
            EXEC1=8'd17,
            XIND2=8'd18,
            XIND3=8'd19,
            XIND4=8'd20,
            YIND2=8'd21,
            YIND3=8'd22,
            YIND4=8'd23,
            ZIND2=8'd24,
            ZIND3=8'd25,
            ZIND4=8'd26,
            EXEC2=8'd27,
            EXEC3=8'd28,
            EXEC4=8'd29,
            EXEC5=8'd30,
            EXEC6=8'd31,
            EXEC7=8'd32,
            EXEC8=8'd33,
            EXEC9=8'd34,
            STOPX1=8'd35,
            STOPX2=8'd36,
            STOPX3=8'd37,
            STOPX4=8'd38,
            STOPX5=8'd39,
            STOPX6=8'd40,
            STOPY1=8'd41,
            STOPY2=8'd42,
            STOPY3=8'd43,
            STOPY4=8'd44,
            STOPY5=8'd45,
            STOPY6=8'd46,
            STOPZ1=8'd47,
            STOPZ2=8'd48,
            STOPZ3=8'd49,
            STOPZ4=8'd50,
            STOPZ5=8'd51,
            STOPZ6=8'd52,
            PAUSE=8'd53,
            PAUSE2=8'd54
    ;

    //-------------------------------------------------------
    assign test_state_machine = state_reg;

    //-----------------------------------------------------

    always @(*) begin
        {mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il} = 0;
        {acc_cl, acc_ld, acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il}=0;
        {mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il}=0;
        {ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il}=0;
        {sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il}=0;
        {pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il}=0;
        data = mdr_out;
        opcode = ir_out[15:12];
        status=1'b0;
        pc_inc=1'b0;
        sp_ld=1'b0;
        pc_in=1'b0;
        sp_in=1'b0;
        pc_ld=1'b0;
        we_next=1'b0;
        mar_in={(ADDR_WIDTH){1'b0}};
        xrez = 4'b0000;
        yrez = 4'b0000;
        zrez = 4'b0000;
        alu_oc_next=alu_oc_reg;
        state_next=state_reg;
        x_reg = ir_out[10:8];
        y_reg = ir_out[6:4];
        z_reg = ir_out[2:0];
        x_adr = ir_out[11]; y_adr = ir_out[7]; z_adr=ir_out[3];
        in_next={(DATA_WIDTH){1'b0}};
        out_next=out_reg;

        //state_next = START;
        case (state_reg) 
        START: begin
            pc_in={{(ADDR_WIDTH-4){1'b0}},4'b1000};
            pc_ld=1'b1;
            sp_in={{(ADDR_WIDTH){1'b1}}};
            sp_ld=1'b1;
            we_next=1'b0;
            in_next={(DATA_WIDTH){1'b0}};
            out_next={(DATA_WIDTH){1'b0}};
            state_next=INFETCH1;
        end
        INFETCH1: begin
            mar_ld<=1'b1;
            mar_in<=pc_out;
            state_next<=INFETCH2;
        end
        INFETCH2: begin
            state_next<=INFETCH3;
        end
        INFETCH3: begin
           // mar_ld<=1'b0;
            //mar_in={(ADDR_WIDTH){1'b0}};
            mdr_ld=1'b1;
            state_next=INFETCH4;
        end
        INFETCH4: begin
            ir_ld=1'b1;
            ir_in={{(DATA_WIDTH){1'b0}},mdr_out};
            pc_inc=1'b1;
            state_next=INDECODE1;
        end
        INDECODE1: begin
            case (opcode)
                MOV:begin
                    //state_next=MOV1;
                    if(z_adr==1'b0 && z_reg==3'b000) begin
                        if(x_adr==1'b0 && y_adr==1'b0) begin
                            xrez={x_adr,x_reg};
                            yrez={y_adr,y_reg};
                            state_next=EXEC1;
                        end
                        else begin
                            state_next=YIND;
                        end
                    end
                    
                end 
                ADD, SUB, MUL, DIV: begin                   
                    if(x_adr==1'b0 && y_adr==1'b0 && z_adr==1'b0) begin
                        xrez={x_adr,x_reg};
                        yrez={y_adr,y_reg};
                        zrez={z_adr,z_reg};
                        state_next=EXEC1;
                    end
                    else begin
                        state_next=ZIND;
                    end                    
                end
                IN: begin
                    if(x_adr==1'b0) begin
                        state_next=EXEC1;
                    end
                    else begin
                        state_next=XIND;
                    end
                end
                OUT: begin
                    if(x_adr==1'b0) begin
                        state_next=EXEC1;
                    end
                    else begin
                        state_next=XIND;
                    end
                end
                STOP: begin
                    if({x_adr, x_reg, y_adr, y_reg, z_adr, z_reg}==12'h000 ) begin
                        state_next=ZIND;
                    end
                    else
                        state_next=STOPX1;
                end
            endcase
        end
        EXEC1:
            case(opcode)
                MOV: begin
                    mar_in = {{(ADDR_WIDTH-4){1'b0}},y_adr,y_reg};
                    mar_ld = 1'b1;
                    we_next=1'b0;
                    state_next=EXEC2;
                end
                ADD,SUB,MUL,DIV:begin
                    mar_ld = 1'b1;
                    mar_in = {{(ADDR_WIDTH-4){1'b0}},y_adr,y_reg};
                    //we_next=1'b0;
                    state_next=EXEC2;
                end
                IN: begin
                    mar_ld = 1'b1;
                    mar_in = {{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                    state_next=EXEC2;
                end
                OUT: begin
                    mar_ld = 1'b1;
                    mar_in = {{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                    state_next=EXEC2;
                end
                STOP: begin
                    
                end
            endcase
        EXEC2: 
            case (opcode)
                MOV: begin
                    state_next=EXEC3;
                end
                ADD,SUB,MUL,DIV: begin
                    state_next=EXEC3;
                end
                IN: begin
                mdr_ld=1'b1;
                
                we_next=1'b1;
                state_next=PAUSE;
                end
                OUT: begin
                state_next=EXEC3;   
                end
                
            endcase
        EXEC3: 
            case (opcode)
                MOV: begin
                    mdr_ld=1'b1;
                    mar_in={{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                    mar_ld=1'b1;
                    state_next=EXEC4;
                end
                ADD,SUB,MUL,DIV: begin
                    mdr_ld=1'b1;
                    state_next=EXEC4;
                    
                end
                IN: begin
                
                //we_next=1'b1;    
                data=in ;
                state_next=INFETCH1;

                end
                OUT: begin
                mdr_ld=1'b1;  
                state_next=EXEC4; 
                end
                
            endcase
        EXEC4: 
            case (opcode)
                MOV: begin
                    we_next=1'b1;
                    state_next=EXEC5;
                end
                ADD,SUB,MUL,DIV: begin
                    alu_a_next=mdr_out;
                    mar_in={{(ADDR_WIDTH-4){1'b0}},z_adr,z_reg};
                    mar_ld=1'b1;
                    //we_next=1'b0;
                    state_next=EXEC5;
                end
                IN: begin
                    

                end
                OUT: begin
                out_next=mem;
                state_next=EXEC5;    
                end
                
            endcase
        EXEC5: 
            case (opcode)
                MOV: begin
                    state_next=INFETCH1;
                end
                ADD,SUB,MUL,DIV: begin
                    state_next=EXEC6;
                end
                IN: begin
                end
                OUT: begin
                state_next=EXEC6;    
                end
                
            endcase
        EXEC6: 
            case (opcode)
                MOV: begin
                    
                end
                ADD,SUB,MUL,DIV: begin
                    mdr_ld=1'b1;
                    
                    state_next=EXEC7;
                end
                IN: begin
                    

                end
                OUT: begin
                    state_next=INFETCH1;
                end
                
            endcase
        EXEC7: 
            case (opcode)
                MOV: begin
                    
                end
                ADD,SUB,MUL,DIV: begin
                    alu_b_next=mdr_out;
                    case (opcode)
                        ADD: alu_oc_next= 3'b000;
                        SUB: alu_oc_next= 3'b001;
                        MUL: alu_oc_next= 3'b010;
                    endcase
                    
                    //mdr_ld=1'b1;
                    mar_in={{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                    mar_ld=1'b1;
                   
                    state_next=EXEC8;
                end
                IN: begin
                    

                end
                OUT: begin
                    
                end
                
        endcase
        EXEC8: 
            case (opcode)
                MOV: begin
                    
                end
                ADD,SUB,MUL,DIV: begin   
                    data=alu_f;  
                    we_next=1'b1;               
                    state_next=EXEC9;
                end
                IN: begin
                    

                end
                OUT: begin
                    
                end
                
        endcase
        EXEC9: 
        case (opcode)
                MOV: begin
                    
                end
                ADD,SUB,MUL,DIV: begin   
                    data=alu_f;              
                    state_next=INFETCH1; 
                end
                IN: begin
                    

                end
                OUT: begin
                    
                end
            
        endcase   

        STOPX1: begin
            if({x_adr,x_reg}!=4'b0000) begin
                mar_ld = 1'b1;
                mar_in = {{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                state_next=STOPX2;
            end
            else state_next=STOPY1;
        end
        STOPX2: begin
            state_next=STOPX3;
        end
        STOPX3: begin
            mdr_ld=1'b1;  
            state_next=STOPX4; 
        end
        STOPX4: begin
            out_next=mem;
            state_next=STOPX5;
        end
        STOPX5: begin
            state_next=STOPY1;
        end
        STOPY1: begin
            if({y_adr,y_reg}!=4'b0000) begin
                mar_ld = 1'b1;
                mar_in = {{(ADDR_WIDTH-4){1'b0}},y_adr,y_reg};
                state_next=STOPY2;
            end
            else state_next=STOPZ1;
        end
        STOPY2: begin
            state_next=STOPY3;
        end
        STOPY3: begin
            mdr_ld=1'b1;  
            state_next=STOPY4; 
        end
        STOPY4: begin
            out_next=mem;
            state_next=STOPY5;
        end
        STOPY5: begin
            state_next=STOPZ1;
        end
        STOPZ1: begin
            if({z_adr,z_reg}!=4'b0000) begin
                mar_ld = 1'b1;
                mar_in = {{(ADDR_WIDTH-4){1'b0}},z_adr,z_reg};
                state_next=STOPZ2;
            end
            else state_next=STOPPED;
        end
        STOPZ2: begin
            state_next=STOPZ3;
        end
        STOPZ3: begin
            mdr_ld=1'b1;  
            state_next=STOPZ4; 
        end
        STOPZ4: begin
            out_next=mem;
            state_next=STOPZ5;
        end
        STOPZ5: begin
            state_next=STOPPED;
        end

        ZIND: begin
            if(z_adr==1'b1) begin
                mar_in={{(ADDR_WIDTH-4){1'b0}},z_adr,z_reg};
                mar_ld=1'b1;
                state_next=ZIND2;
            end
            else begin
                state_next=YIND;
            end
            
        end
        ZIND2: begin
            state_next=ZIND3;
        end
        ZIND3: begin
            mdr_ld=1'b1;
            state_next=ZIND4;
        end
        ZIND4: begin
            z_reg=mdr_out[2:0];
            z_adr=mdr_out[3];
            state_next=YIND;
        end
        YIND: begin
            if(y_adr==1'b1) begin
                mar_in={{(ADDR_WIDTH-4){1'b0}},y_adr,y_reg};
                mar_ld=1'b1;
                state_next=YIND2;
            end
            else begin
                state_next=XIND;
            end
        end
        YIND2: begin
            state_next=YIND3;
        end
        YIND3: begin
            mdr_ld=1'b1;
            state_next=YIND4;
        end
        YIND4: begin
            y_reg=mdr_out[2:0];
            y_adr=mdr_out[3];
            state_next=XIND;
        end
        XIND: begin
            if(x_adr==1'b1) begin
                mar_in={{(ADDR_WIDTH-4){1'b0}},x_adr,x_reg};
                mar_ld=1'b1;
                state_next<=XIND2;
            end
            else begin
                state_next<=EXEC1;
            end
        end
        XIND2: begin
            state_next<=XIND3;
        end
        XIND3: begin
            mdr_ld=1'b1;
            state_next<=XIND4;
        end
        XIND4: begin
            x_reg=mdr_out[2:0];
            x_adr=mdr_out[3];
            xrez={x_adr,x_reg};
            state_next<=EXEC1;
        end
        PAUSE: begin
            we_next = 1'b1;
            status = 1'b1;
            if (!control) begin
                state_next = PAUSE;             
            end
            else begin                    
                data = in;
                state_next = INFETCH1;
            end
        end
        STOPPED:
        begin
                
        end
        endcase

    end


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= START;
            out_reg <= {DATA_WIDTH{1'b0}};
            alu_a_reg={DATA_WIDTH{1'b0}};
            alu_b_reg={DATA_WIDTH{1'b0}};
            alu_oc_reg=3'b000;
            
            we_reg <= 1'b0;
        end
        else begin
            out_reg<=out_next;
            we_reg<=we_next;
            alu_a_reg<=alu_a_next;
            alu_b_reg<=alu_b_next;
            alu_oc_reg<=alu_oc_next;

            state_reg<=state_next;
            

        end
    end


   


endmodule