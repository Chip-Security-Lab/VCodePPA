//SystemVerilog
module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    input valid_in,
    output reg valid_out,
    output reg detected
);
    // Stage 1: Input capture and first bit of pattern
    reg [0:0] state_stage1;
    reg valid_stage1;
    
    // Stage 2: Second bit of pattern
    reg [1:0] state_stage2;
    reg valid_stage2;
    
    // Stage 3: Third bit of pattern
    reg [2:0] state_stage3;
    reg valid_stage3;
    
    // Stage 4: Final bit and pattern detection
    reg [3:0] state_stage4;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= data_in;
            valid_stage1 <= valid_in;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            state_stage2 <= {state_stage1, data_in};
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= 3'b000;
            valid_stage3 <= 1'b0;
        end else begin
            state_stage3 <= {state_stage2, data_in};
            valid_stage3 <= valid_stage2;
        end
    end

    // Pipeline stage 4 (final stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4 <= 4'b0000;
            detected <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            state_stage4 <= {state_stage3, data_in};
            detected <= ({state_stage3, data_in} == PATTERN);
            valid_out <= valid_stage3;
        end
    end
endmodule