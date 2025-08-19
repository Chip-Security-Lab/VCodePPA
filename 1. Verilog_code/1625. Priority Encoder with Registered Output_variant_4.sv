//SystemVerilog
module priority_encoder_valid_ready (
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_in,
    output reg ready_out,
    output reg [2:0] data_out,
    output reg valid_out,
    input ready_in
);

    reg [2:0] grant_id;
    reg [7:0] requests_reg;
    reg valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            requests_reg <= 8'b0;
            valid_reg <= 1'b0;
            grant_id <= 3'd0;
            data_out <= 3'd0;
            valid_out <= 1'b0;
            ready_out <= 1'b1;
        end else begin
            if (valid_in && ready_out) begin
                requests_reg <= data_in;
                valid_reg <= 1'b1;
            end

            if (valid_reg && ready_in) begin
                valid_out <= 1'b1;
                if (requests_reg[0]) data_out <= 3'd0;
                else if (requests_reg[1]) data_out <= 3'd1;
                else if (requests_reg[2]) data_out <= 3'd2;
                else if (requests_reg[3]) data_out <= 3'd3;
                else if (requests_reg[4]) data_out <= 3'd4;
                else if (requests_reg[5]) data_out <= 3'd5;
                else if (requests_reg[6]) data_out <= 3'd6;
                else if (requests_reg[7]) data_out <= 3'd7;
                else data_out <= 3'd0;
            end else if (!ready_in) begin
                valid_out <= 1'b0;
            end

            ready_out <= !valid_reg || (valid_reg && ready_in);
        end
    end

endmodule