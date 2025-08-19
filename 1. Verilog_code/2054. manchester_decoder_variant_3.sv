//SystemVerilog
module manchester_decoder (
    input wire clk,
    input wire rst_n,
    input wire sample_en,
    input wire manchester_in,
    output reg data_out,
    output reg valid_out
);

    // Stage 1: State machine and prev_sample update
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    reg prev_sample_stage1;
    reg prev_sample_stage2;
    reg manchester_in_stage1;
    reg manchester_in_stage2;
    reg sample_en_stage1;
    reg sample_en_stage2;

    // Stage 2: Decode logic and output register prep
    reg data_out_next_stage2;
    reg data_out_stage3;
    reg valid_out_next_stage2;
    reg valid_out_stage3;

    // Stage 1: Register state, previous sample, input, and sample_en
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= 2'b00;
            prev_sample_stage1 <= 1'b0;
            manchester_in_stage1 <= 1'b0;
            sample_en_stage1 <= 1'b0;
        end else begin
            sample_en_stage1 <= sample_en;
            manchester_in_stage1 <= manchester_in;
            // State transition
            if (sample_en) begin
                case (state_stage1)
                    2'b00: state_stage1 <= 2'b01;
                    2'b01: state_stage1 <= 2'b00;
                    default: state_stage1 <= 2'b00;
                endcase
            end
            // Capture previous sample at state 00
            if (sample_en && state_stage1 == 2'b00) begin
                prev_sample_stage1 <= manchester_in;
            end
        end
    end

    // Stage 2: Pipeline registers for state, prev_sample, input, and sample_en
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= 2'b00;
            prev_sample_stage2 <= 1'b0;
            manchester_in_stage2 <= 1'b0;
            sample_en_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            prev_sample_stage2 <= prev_sample_stage1;
            manchester_in_stage2 <= manchester_in_stage1;
            sample_en_stage2 <= sample_en_stage1;
        end
    end

    // Stage 2: Compute next data and valid signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_next_stage2 <= 1'b0;
            valid_out_next_stage2 <= 1'b0;
        end else begin
            if (state_stage2 == 2'b01) begin
                data_out_next_stage2 <= (prev_sample_stage2 == 1'b0 && manchester_in_stage2 == 1'b1);
                valid_out_next_stage2 <= sample_en_stage2 ? 1'b1 : 1'b0;
            end else begin
                data_out_next_stage2 <= data_out_stage3;
                valid_out_next_stage2 <= 1'b0;
            end
        end
    end

    // Stage 3: Output registers for data and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 1'b0;
            valid_out_stage3 <= 1'b0;
        end else begin
            data_out_stage3 <= data_out_next_stage2;
            valid_out_stage3 <= valid_out_next_stage2;
        end
    end

    // Stage 4: Final output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_out <= data_out_stage3;
            valid_out <= valid_out_stage3;
        end
    end

endmodule