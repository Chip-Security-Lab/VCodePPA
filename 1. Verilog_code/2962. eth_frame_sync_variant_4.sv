//SystemVerilog
module eth_frame_sync #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [IN_WIDTH-1:0] data_in,
    input wire in_valid,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg out_valid,
    output reg sof,
    output reg eof
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    
    // Stage 1: Input capturing and first shift register
    reg [IN_WIDTH-1:0] data_in_stage1;
    reg in_valid_stage1;
    reg [IN_WIDTH*(RATIO-1)-1:0] shift_reg_stage1;
    
    // Stage 2: Complete shift register and pattern detection
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage2;
    reg [3:0] count_stage1, count_stage2;
    reg sof_pattern_detected_stage1, sof_pattern_detected_stage2;
    reg prev_sof_stage1, prev_sof_stage2;
    
    // Stage 3: Frame processing
    reg frame_end_stage2, frame_end_stage3;
    reg sof_detected_stage2, sof_detected_stage3;
    reg count_last_stage2, count_last_stage3;
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage3;
    
    // Stage 4: Output preparation
    reg [OUT_WIDTH-1:0] data_out_stage3, data_out_stage4;
    reg out_valid_stage3, out_valid_stage4;
    reg sof_stage3, sof_stage4;
    reg eof_stage3, eof_stage4;
    
    // Stage 1: Input capturing
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= {IN_WIDTH{1'b0}};
            in_valid_stage1 <= 1'b0;
            shift_reg_stage1 <= {(IN_WIDTH*(RATIO-1)){1'b0}};
        end else begin
            data_in_stage1 <= data_in;
            in_valid_stage1 <= in_valid;
            if (in_valid) begin
                shift_reg_stage1 <= shift_reg_stage2[IN_WIDTH*RATIO-1:IN_WIDTH];
            end
        end
    end
    
    // Stage 1: SOF pattern detection and counter logic
    always @(posedge clk) begin
        if (rst) begin
            sof_pattern_detected_stage1 <= 1'b0;
            prev_sof_stage1 <= 1'b0;
            count_stage1 <= 4'b0;
        end else if (in_valid) begin
            // SOF pattern detection
            if (data_in === 8'hD5 && !prev_sof_stage1) begin
                sof_pattern_detected_stage1 <= 1'b1;
                prev_sof_stage1 <= 1'b1;
            end else begin
                sof_pattern_detected_stage1 <= 1'b0;
                prev_sof_stage1 <= prev_sof_stage1;
            end
            
            // Counter logic
            if (sof_pattern_detected_stage1) begin
                count_stage1 <= 4'b0;
            end else if (count_stage1 === RATIO-1) begin
                count_stage1 <= 4'b0;
            end else begin
                count_stage1 <= count_stage1 + 4'b1;
            end
        end else begin
            sof_pattern_detected_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Complete shift register and count advancement
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= {(IN_WIDTH*RATIO){1'b0}};
            count_stage2 <= 4'b0;
            sof_pattern_detected_stage2 <= 1'b0;
            prev_sof_stage2 <= 1'b0;
            count_last_stage2 <= 1'b0;
        end else begin
            if (in_valid_stage1) begin
                shift_reg_stage2 <= {shift_reg_stage1, data_in_stage1};
            end
            count_stage2 <= count_stage1;
            sof_pattern_detected_stage2 <= sof_pattern_detected_stage1;
            prev_sof_stage2 <= prev_sof_stage1;
            count_last_stage2 <= (count_stage1 === RATIO-1);
        end
    end
    
    // Stage 2: Frame end detection
    always @(posedge clk) begin
        if (rst) begin
            frame_end_stage2 <= 1'b0;
            sof_detected_stage2 <= 1'b0;
        end else begin
            // Frame end detection
            if (in_valid_stage1 && count_stage1 === RATIO-1) begin
                frame_end_stage2 <= (shift_reg_stage1[IN_WIDTH*(RATIO-1)-1 -: 8] === 8'hFD);
            end else begin
                frame_end_stage2 <= 1'b0;
            end
            
            // SOF detection passing
            sof_detected_stage2 <= sof_pattern_detected_stage1;
        end
    end
    
    // Stage 3: Frame processing and output preparation
    always @(posedge clk) begin
        if (rst) begin
            frame_end_stage3 <= 1'b0;
            sof_detected_stage3 <= 1'b0;
            count_last_stage3 <= 1'b0;
            shift_reg_stage3 <= {(IN_WIDTH*RATIO){1'b0}};
            data_out_stage3 <= {OUT_WIDTH{1'b0}};
            out_valid_stage3 <= 1'b0;
        end else begin
            frame_end_stage3 <= frame_end_stage2;
            sof_detected_stage3 <= sof_detected_stage2;
            count_last_stage3 <= count_last_stage2;
            shift_reg_stage3 <= shift_reg_stage2;
            
            // Output data preparation
            if (count_last_stage2) begin
                data_out_stage3 <= shift_reg_stage2;
                out_valid_stage3 <= 1'b1;
            end else begin
                out_valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Stage 3: SOF and EOF signals preparation
    always @(posedge clk) begin
        if (rst) begin
            sof_stage3 <= 1'b0;
            eof_stage3 <= 1'b0;
        end else begin
            sof_stage3 <= sof_detected_stage2;
            eof_stage3 <= frame_end_stage2;
        end
    end
    
    // Stage 4: Final output stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {OUT_WIDTH{1'b0}};
            out_valid <= 1'b0;
            sof <= 1'b0;
            eof <= 1'b0;
        end else begin
            data_out <= data_out_stage3;
            out_valid <= out_valid_stage3;
            sof <= sof_stage3;
            eof <= eof_stage3;
        end
    end
    
endmodule