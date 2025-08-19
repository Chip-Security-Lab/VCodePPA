module rle_encoder #(parameter DATA_WIDTH = 8) (
    input                      clk,
    input                      rst_n,
    input                      valid_in,
    input      [DATA_WIDTH-1:0] data_in,
    output reg                 valid_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_WIDTH-1:0] count_out
);
    reg [DATA_WIDTH-1:0] current_data;
    reg [DATA_WIDTH-1:0] run_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_data <= 0;
            run_count <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            if (data_in == current_data && run_count < {DATA_WIDTH{1'b1}}) begin
                run_count <= run_count + 1;
            end else begin
                data_out <= current_data;
                count_out <= run_count;
                valid_out <= (run_count != 0);
                current_data <= data_in;
                run_count <= 1;
            end
        end else begin
            valid_out <= 0;
        end
    end
endmodule