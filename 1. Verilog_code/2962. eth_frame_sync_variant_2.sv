//SystemVerilog
module eth_frame_sync #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32
)(
    input clk,
    input rst,
    input [IN_WIDTH-1:0] data_in,
    input in_valid,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg out_valid,
    output reg sof,
    output reg eof
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    
    // Pipeline registers for input data
    reg [IN_WIDTH-1:0] data_in_stage1;
    reg in_valid_stage1;
    
    // SOF detection pipeline registers
    reg [IN_WIDTH-1:0] sof_data_stage1;
    reg sof_detected_stage1;
    reg sof_detected_stage2;
    reg sof_detected_stage3;
    reg prev_sof_stage1;
    reg prev_sof_stage2;
    
    // Shift register pipeline
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage1;
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage2;
    
    // Counter pipeline
    reg [2:0] count_stage1;
    reg [2:0] count_stage2;
    
    // Control signals pipeline
    reg output_ready_stage1;
    reg output_ready_stage2;
    reg output_ready_stage3;
    
    // EOF detection pipeline
    reg eof_detected_stage1;
    reg eof_detected_stage2;
    reg eof_detected_stage3;
    
    // Start and end frame markers
    localparam [7:0] SOF_MARKER = 8'hD5;
    localparam [7:0] EOF_MARKER = 8'hFD;
    
    // Stage 1: Input registration and basic detection
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= {IN_WIDTH{1'b0}};
            in_valid_stage1 <= 1'b0;
            sof_data_stage1 <= {IN_WIDTH{1'b0}};
        end
        else begin
            data_in_stage1 <= data_in;
            in_valid_stage1 <= in_valid;
            sof_data_stage1 <= data_in;
        end
    end
    
    // Stage 2: SOF detection logic
    always @(posedge clk) begin
        if (rst) begin
            prev_sof_stage1 <= 1'b0;
            prev_sof_stage2 <= 1'b0;
            sof_detected_stage1 <= 1'b0;
        end
        else if (in_valid_stage1) begin
            sof_detected_stage1 <= (sof_data_stage1 == SOF_MARKER && !prev_sof_stage1);
            prev_sof_stage1 <= (sof_data_stage1 == SOF_MARKER) ? 1'b1 : prev_sof_stage1;
            prev_sof_stage2 <= prev_sof_stage1;
        end
        else begin
            sof_detected_stage1 <= 1'b0;
        end
    end
    
    // Stage 3: Data shifting
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage1 <= {(IN_WIDTH*RATIO){1'b0}};
            count_stage1 <= 3'b000;
        end 
        else if (in_valid_stage1) begin
            // Data shifting
            shift_reg_stage1 <= {shift_reg_stage1[IN_WIDTH*(RATIO-1)-1:0], data_in_stage1};
            
            // Counter logic
            if (count_stage1 == RATIO-1) begin
                count_stage1 <= 3'b000;
            end 
            else begin
                count_stage1 <= count_stage1 + 3'b001;
            end
        end
    end
    
    // Stage 4: Count and shift register pipeline
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= {(IN_WIDTH*RATIO){1'b0}};
            count_stage2 <= 3'b000;
            sof_detected_stage2 <= 1'b0;
        end
        else begin
            shift_reg_stage2 <= shift_reg_stage1;
            count_stage2 <= count_stage1;
            sof_detected_stage2 <= sof_detected_stage1;
        end
    end
    
    // Stage 5: Output preparation logic
    always @(posedge clk) begin
        if (rst) begin
            output_ready_stage1 <= 1'b0;
            eof_detected_stage1 <= 1'b0;
        end
        else if (in_valid_stage1) begin
            // Output generation logic preparation
            if (count_stage2 == RATIO-1) begin
                output_ready_stage1 <= 1'b1;
                // EOF detection
                eof_detected_stage1 <= (shift_reg_stage2[IN_WIDTH*(RATIO-2)-1:0] == EOF_MARKER);
            end 
            else begin
                output_ready_stage1 <= 1'b0;
                eof_detected_stage1 <= 1'b0;
            end
        end
        else begin
            output_ready_stage1 <= 1'b0;
            eof_detected_stage1 <= 1'b0;
        end
    end
    
    // Stage 6: Pipeline registers for control signals
    always @(posedge clk) begin
        if (rst) begin
            output_ready_stage2 <= 1'b0;
            output_ready_stage3 <= 1'b0;
            eof_detected_stage2 <= 1'b0;
            eof_detected_stage3 <= 1'b0;
            sof_detected_stage3 <= 1'b0;
        end
        else begin
            output_ready_stage2 <= output_ready_stage1;
            output_ready_stage3 <= output_ready_stage2;
            eof_detected_stage2 <= eof_detected_stage1;
            eof_detected_stage3 <= eof_detected_stage2;
            sof_detected_stage3 <= sof_detected_stage2;
        end
    end
    
    // Stage 7: Final output registration stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {OUT_WIDTH{1'b0}};
            out_valid <= 1'b0;
            sof <= 1'b0;
            eof <= 1'b0;
        end
        else begin
            // Register output signals based on pipeline values
            data_out <= output_ready_stage3 ? shift_reg_stage2 : data_out;
            out_valid <= output_ready_stage3;
            sof <= sof_detected_stage3;
            eof <= eof_detected_stage3 && output_ready_stage3;
        end
    end
endmodule