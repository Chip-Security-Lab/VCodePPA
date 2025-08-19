//SystemVerilog
module manchester_decoder (
    input wire clk,
    input wire rst_n,
    input wire sample_en,
    input wire manchester_in,
    output reg data_out,
    output reg valid_out
);

    // Pipeline Stage 1: Sample input and state machine
    reg [1:0] state_stage1;
    reg prev_sample_stage1;
    reg manchester_in_stage1;
    reg sample_en_stage1;
    reg [1:0] state_next_stage1;
    reg prev_sample_next_stage1;
    reg valid_stage1;

    // Pipeline Stage 2: Decode Manchester and generate outputs
    reg data_out_stage2;
    reg valid_stage2;
    reg sample_en_stage2;
    reg [1:0] state_stage2;
    reg prev_sample_stage2;
    reg manchester_in_stage2;

    // Stage 1: State machine and input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= 2'b00;
            prev_sample_stage1 <= 1'b0;
            manchester_in_stage1 <= 1'b0;
            sample_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            manchester_in_stage1 <= manchester_in;
            sample_en_stage1 <= sample_en;
            state_stage1 <= state_next_stage1;
            prev_sample_stage1 <= prev_sample_next_stage1;
            valid_stage1 <= sample_en;
        end
    end

    // Next-state logic for state machine (combinational)
    always @(*) begin
        state_next_stage1 = state_stage1;
        prev_sample_next_stage1 = prev_sample_stage1;
        if (sample_en) begin
            case (state_stage1)
                2'b00: begin
                    prev_sample_next_stage1 = manchester_in;
                    state_next_stage1 = 2'b01;
                end
                2'b01: begin
                    state_next_stage1 = 2'b00;
                end
                default: state_next_stage1 = 2'b00;
            endcase
        end
    end

    // Stage 2: Data decoding and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            sample_en_stage2 <= 1'b0;
            state_stage2 <= 2'b00;
            prev_sample_stage2 <= 1'b0;
            manchester_in_stage2 <= 1'b0;
        end else begin
            sample_en_stage2 <= sample_en_stage1;
            state_stage2 <= state_stage1;
            prev_sample_stage2 <= prev_sample_stage1;
            manchester_in_stage2 <= manchester_in_stage1;
            valid_stage2 <= valid_stage1;

            if (sample_en_stage1 && state_stage1 == 2'b01) begin
                data_out_stage2 <= (prev_sample_stage1 == 1'b0 && manchester_in_stage1 == 1'b1);
            end else begin
                data_out_stage2 <= data_out_stage2;
            end
        end
    end

    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_out <= data_out_stage2;
            if (sample_en_stage2 && state_stage2 == 2'b01) begin
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule