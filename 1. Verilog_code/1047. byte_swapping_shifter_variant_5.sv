//SystemVerilog
module byte_swapping_shifter_valid_ready (
    input              clk,
    input              rst_n,
    input  [31:0]      data_in,
    input  [1:0]       swap_mode,
    input              data_in_valid,
    output             data_in_ready,
    output reg [31:0]  data_out,
    output reg         data_out_valid,
    input              data_out_ready
);

    reg        [31:0]  data_in_latched;
    reg        [1:0]   swap_mode_latched;
    reg                busy;
    reg        [31:0]  swap_result;
    reg        [1:0]   swap_mode_pipeline;
    reg        [31:0]  data_in_pipeline;
    reg                pipeline_valid;

    assign data_in_ready = !busy;

    // Pipeline input handshake and move registers after combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy               <= 1'b0;
            data_in_latched    <= 32'b0;
            swap_mode_latched  <= 2'b0;
            data_out           <= 32'b0;
            data_out_valid     <= 1'b0;
            swap_result        <= 32'b0;
            swap_mode_pipeline <= 2'b0;
            data_in_pipeline   <= 32'b0;
            pipeline_valid     <= 1'b0;
        end else begin
            // Input handshake signal
            if (data_in_valid && data_in_ready) begin
                data_in_latched    <= data_in;
                swap_mode_latched  <= swap_mode;
                busy               <= 1'b1;
                pipeline_valid     <= 1'b1;
                data_in_pipeline   <= data_in;
                swap_mode_pipeline <= swap_mode;
            end else if (!pipeline_valid && busy && !data_out_valid) begin
                pipeline_valid     <= 1'b1;
                data_in_pipeline   <= data_in_latched;
                swap_mode_pipeline <= swap_mode_latched;
            end

            // Move swap logic after pipeline registers
            if (pipeline_valid) begin
                case (swap_mode_pipeline)
                    2'b00: swap_result <= data_in_pipeline;
                    2'b01: swap_result <= {data_in_pipeline[7:0], data_in_pipeline[15:8], data_in_pipeline[23:16], data_in_pipeline[31:24]};
                    2'b10: swap_result <= {data_in_pipeline[15:0], data_in_pipeline[31:16]};
                    2'b11: swap_result <= {
                        data_in_pipeline[0], data_in_pipeline[1], data_in_pipeline[2], data_in_pipeline[3], data_in_pipeline[4],
                        data_in_pipeline[5], data_in_pipeline[6], data_in_pipeline[7], data_in_pipeline[8], data_in_pipeline[9],
                        data_in_pipeline[10], data_in_pipeline[11], data_in_pipeline[12], data_in_pipeline[13], data_in_pipeline[14],
                        data_in_pipeline[15], data_in_pipeline[16], data_in_pipeline[17], data_in_pipeline[18], data_in_pipeline[19],
                        data_in_pipeline[20], data_in_pipeline[21], data_in_pipeline[22], data_in_pipeline[23], data_in_pipeline[24],
                        data_in_pipeline[25], data_in_pipeline[26], data_in_pipeline[27], data_in_pipeline[28], data_in_pipeline[29],
                        data_in_pipeline[30], data_in_pipeline[31]};
                    default: swap_result <= data_in_pipeline;
                endcase
            end

            // Output logic
            if (pipeline_valid) begin
                data_out       <= swap_result;
                data_out_valid <= 1'b1;
                pipeline_valid <= 1'b0;
            end else if (data_out_valid && data_out_ready) begin
                data_out_valid <= 1'b0;
                busy           <= 1'b0;
            end
        end
    end

endmodule