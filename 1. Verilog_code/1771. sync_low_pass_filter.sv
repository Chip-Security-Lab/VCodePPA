module sync_low_pass_filter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] prev_sample;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            prev_sample <= {DATA_WIDTH{1'b0}};
        end else begin
            // Simple low-pass: y[n] = 0.75*x[n] + 0.25*y[n-1]
            data_out <= (data_in >> 2) + (data_in >> 1) + (prev_sample >> 2);
            prev_sample <= data_out;
        end
    end
endmodule