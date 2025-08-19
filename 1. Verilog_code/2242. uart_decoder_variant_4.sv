//SystemVerilog
module uart_decoder #(parameter BAUD_RATE=9600) (
    input rx, clk, rst_n,
    output reg [7:0] data_out,
    output reg valid_out,
    output reg parity_err_out
);
    // Pipeline stage 1: Sampling and bit detection
    reg [3:0] sample_cnt;
    reg [2:0] bit_cnt_stage1;
    reg [7:0] shift_reg_stage1;
    reg parity_stage1;
    reg active_stage1;
    reg valid_stage1;
    
    wire mid_sample = (sample_cnt == 4'd7);
    wire start_bit = !rx && !active_stage1;
    wire stop_bit = (bit_cnt_stage1 == 3'd7) && mid_sample;
    
    // Pipeline stage 2: Bit processing
    reg [2:0] bit_cnt_stage2;
    reg [7:0] shift_reg_stage2;
    reg parity_stage2;
    reg active_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Parity check and output
    reg [7:0] data_stage3;
    reg parity_err_stage3;
    reg valid_stage3;

    // Stage 1: Sampling logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt <= 4'd0;
            bit_cnt_stage1 <= 3'd0;
            shift_reg_stage1 <= 8'd0;
            parity_stage1 <= 1'b0;
            active_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b0;
            
            if (start_bit) begin
                sample_cnt <= 4'd0;
                bit_cnt_stage1 <= 3'd0;
                active_stage1 <= 1'b1;
                parity_stage1 <= 1'b0;
            end else if (active_stage1) begin
                if (sample_cnt < 4'd15) begin
                    sample_cnt <= sample_cnt + 1'b1;
                end
                
                if (mid_sample) begin
                    if (bit_cnt_stage1 < 3'd7) begin
                        shift_reg_stage1 <= {rx, shift_reg_stage1[7:1]};
                        parity_stage1 <= parity_stage1 ^ rx;
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    end else begin
                        // Last bit processed
                        active_stage1 <= 1'b0;
                        valid_stage1 <= 1'b1;
                    end
                end
            end
        end
    end
    
    // Stage 2: Bit processing pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'd0;
            bit_cnt_stage2 <= 3'd0;
            parity_stage2 <= 1'b0;
            active_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                shift_reg_stage2 <= shift_reg_stage1;
                bit_cnt_stage2 <= bit_cnt_stage1;
                parity_stage2 <= parity_stage1;
                active_stage2 <= active_stage1;
            end
        end
    end
    
    // Stage 3: Parity check and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 8'd0;
            parity_err_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                data_stage3 <= shift_reg_stage2;
                parity_err_stage3 <= (^shift_reg_stage2) ^ parity_stage2;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'd0;
            parity_err_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage3;
            if (valid_stage3) begin
                data_out <= data_stage3;
                parity_err_out <= parity_err_stage3;
            end
        end
    end
endmodule