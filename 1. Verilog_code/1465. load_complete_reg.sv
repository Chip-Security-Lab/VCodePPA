module load_complete_reg(
    input clk, rst,
    input [15:0] data_in,
    input load,
    output reg [15:0] data_out,
    output reg load_done
);
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
            load_done <= 1'b0;
        end else begin
            load_done <= load;  // Flag active one cycle after load
            if (load)
                data_out <= data_in;
        end
    end
endmodule