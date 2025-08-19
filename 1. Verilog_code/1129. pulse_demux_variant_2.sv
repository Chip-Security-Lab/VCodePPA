//SystemVerilog
module pulse_demux (
    input  wire       clk,        // System clock
    input  wire       pulse_in,   // Input pulse
    input  wire [1:0] route_sel,  // Routing selection
    output reg  [3:0] pulse_out   // Output pulses
);

    // Stage 1: Input registration pipeline
    reg pulse_stage1;
    reg [1:0] route_stage1;

    // Stage 2: Edge detection pipeline
    reg pulse_prev;        // Previous pulse state
    reg pulse_detected;    // Rising edge detected flag
    reg [1:0] route_stage2;

    // Stage 3: Output decode preparation
    reg pulse_valid_stage3;
    reg [1:0] route_stage3;
    
    // Stage 4: Output decoding stage
    reg pulse_valid_stage4;
    reg [3:0] out_decode_stage4;
    
    // Stage 5: Output preparation
    reg [3:0] out_decode_stage5;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        // Register input signals
        pulse_stage1 <= pulse_in;
        route_stage1 <= route_sel;
    end

    // Stage 2: Edge detection
    always @(posedge clk) begin
        pulse_prev <= pulse_stage1;
        pulse_detected <= pulse_stage1 && !pulse_prev;
        route_stage2 <= route_stage1;
    end

    // Stage 3: Decode preparation
    always @(posedge clk) begin
        pulse_valid_stage3 <= pulse_detected;
        route_stage3 <= route_stage2;
    end

    // Stage 4: Output decoding
    always @(posedge clk) begin
        pulse_valid_stage4 <= pulse_valid_stage3;
        
        out_decode_stage4 <= 4'b0000;
        if (pulse_valid_stage3)
            case (route_stage3)
                2'b00: out_decode_stage4 <= 4'b0001;
                2'b01: out_decode_stage4 <= 4'b0010;
                2'b10: out_decode_stage4 <= 4'b0100;
                2'b11: out_decode_stage4 <= 4'b1000;
            endcase
    end
    
    // Stage 5: Output preparation
    always @(posedge clk) begin
        out_decode_stage5 <= out_decode_stage4;
    end

    // Final stage: Output registration
    always @(posedge clk) begin
        pulse_out <= out_decode_stage5;
    end

endmodule