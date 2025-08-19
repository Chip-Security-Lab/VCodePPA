//SystemVerilog
module MIPI_AsyncTransmitter #(
    parameter DELAY_CYCLES = 3
)(
    input wire clk,
    input wire rst_n,
    input wire tx_req,
    input wire [7:0] tx_payload,
    output wire tx_ready,
    output reg lp_mode,
    output reg hs_mode,
    output reg [7:0] hs_data
);

    // Pipeline stage 1 - Request processing
    reg [1:0] delay_counter_stage1;
    reg tx_req_stage1;
    reg [7:0] tx_payload_stage1;
    reg valid_stage1;

    // Pipeline stage 2 - Mode control
    reg hs_mode_stage2;
    reg lp_mode_stage2;
    reg [7:0] hs_data_stage2;
    reg valid_stage2;

    // Pipeline stage 3 - Output stage
    reg hs_mode_stage3;
    reg lp_mode_stage3;
    reg [7:0] hs_data_stage3;
    reg valid_stage3;

    // Stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_counter_stage1 <= DELAY_CYCLES;
            tx_req_stage1 <= 1'b0;
            tx_payload_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            tx_req_stage1 <= tx_req;
            tx_payload_stage1 <= tx_payload;
            valid_stage1 <= tx_req;
            if (tx_req) begin
                delay_counter_stage1 <= DELAY_CYCLES;
            end else if (|delay_counter_stage1) begin
                delay_counter_stage1 <= delay_counter_stage1 - 1;
            end
        end
    end

    // Stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_mode_stage2 <= 1'b0;
            lp_mode_stage2 <= 1'b1;
            hs_data_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1 && (delay_counter_stage1 == 0)) begin
                hs_mode_stage2 <= 1'b1;
                lp_mode_stage2 <= 1'b0;
                hs_data_stage2 <= tx_payload_stage1;
            end else begin
                hs_mode_stage2 <= 1'b0;
                lp_mode_stage2 <= 1'b1;
                hs_data_stage2 <= 8'h00;
            end
        end
    end

    // Stage 3 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_mode_stage3 <= 1'b0;
            lp_mode_stage3 <= 1'b1;
            hs_data_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            hs_mode_stage3 <= hs_mode_stage2;
            lp_mode_stage3 <= lp_mode_stage2;
            hs_data_stage3 <= hs_data_stage2;
        end
    end

    // Output assignments
    assign tx_ready = (delay_counter_stage1 == 0);
    assign hs_mode = hs_mode_stage3;
    assign lp_mode = lp_mode_stage3;
    assign hs_data = hs_data_stage3;

endmodule