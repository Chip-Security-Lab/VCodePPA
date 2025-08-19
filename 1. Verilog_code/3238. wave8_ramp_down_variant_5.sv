//SystemVerilog
module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             valid_in,
    output wire             valid_out,
    output wire             ready_in,
    input  wire             ready_out,
    output wire [WIDTH-1:0] wave_out
);
    // Pipeline stage registers for data
    reg [WIDTH-1:0] wave_stage1;
    reg [WIDTH-1:0] wave_stage2;
    reg [WIDTH-1:0] wave_stage3;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline handshaking logic
    wire stall = valid_stage3 && !ready_out;
    assign ready_in = !stall;
    assign valid_out = valid_stage3;
    assign wave_out = wave_stage3;
    
    // Control signals for case statements
    wire [1:0] stage1_ctrl = {rst, stall};
    wire [1:0] stage2_ctrl = {rst, stall};
    wire [2:0] stage3_ctrl = {rst, stall, valid_stage2};
    
    // Stage 1: Initialize or decrement value
    always @(posedge clk) begin
        case (stage1_ctrl)
            2'b10, 2'b11: begin  // rst == 1
                wave_stage1 <= {WIDTH{1'b1}};
                valid_stage1 <= 1'b0;
            end
            2'b01: begin  // stall == 1, rst == 0
                // Hold values during stall
            end
            2'b00: begin  // stall == 0, rst == 0
                if (valid_in) begin
                    wave_stage1 <= wave_stage3 - STEP;
                    valid_stage1 <= 1'b1;
                end else begin
                    valid_stage1 <= 1'b0;
                end
            end
        endcase
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clk) begin
        case (stage2_ctrl)
            2'b10, 2'b11: begin  // rst == 1
                wave_stage2 <= 0;
                valid_stage2 <= 1'b0;
            end
            2'b01: begin  // stall == 1, rst == 0
                // Hold values during stall
            end
            2'b00: begin  // stall == 0, rst == 0
                wave_stage2 <= wave_stage1;
                valid_stage2 <= valid_stage1;
            end
        endcase
    end
    
    // Stage 3: Final output stage
    always @(posedge clk) begin
        case (stage3_ctrl[2:1])
            2'b10, 2'b11: begin  // rst == 1
                wave_stage3 <= 0;
                valid_stage3 <= 1'b0;
            end
            2'b01: begin  // stall == 1, rst == 0
                // Maintain output during stall (implicit retention)
            end
            2'b00: begin  // stall == 0, rst == 0
                wave_stage3 <= wave_stage2;
                valid_stage3 <= valid_stage2;
            end
        endcase
    end
endmodule