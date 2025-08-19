//SystemVerilog
module wave12_glitch #(
    parameter WIDTH = 8,
    parameter GLITCH_PERIOD = 20
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // Stage 1: Counter and glitch control
    reg [WIDTH-1:0] main_cnt_stage1;
    reg glitch_stage1;
    reg glitch_toggle_stage1;
    
    // Stage 2: Output generation
    reg [WIDTH-1:0] wave_out_stage2;
    reg glitch_stage2;
    
    // Stage 1: Counter logic and glitch detection
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            main_cnt_stage1 <= 0;
            glitch_stage1 <= 0;
            glitch_toggle_stage1 <= 0;
        end else begin
            main_cnt_stage1 <= main_cnt_stage1 + 1;
            glitch_toggle_stage1 <= (main_cnt_stage1 == GLITCH_PERIOD);
            
            if(glitch_toggle_stage1) 
                glitch_stage1 <= ~glitch_stage1;
        end
    end
    
    // Stage 2: Output wave generation
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            glitch_stage2 <= 0;
            wave_out_stage2 <= 0;
        end else begin
            glitch_stage2 <= glitch_stage1;
            wave_out_stage2 <= glitch_stage2 ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
        end
    end
    
    // Output assignment
    assign wave_out = wave_out_stage2;
endmodule