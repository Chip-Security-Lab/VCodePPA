module parity_check_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire parity_in,
    output reg [7:0] data_out,
    output reg valid,
    output reg error
);
    wire calculated_parity;
    
    assign calculated_parity = ^data_in;
    
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
            valid <= 1'b0;
            error <= 1'b0;
        end else begin
            valid <= 1'b1;
            if (parity_in == calculated_parity) begin
                data_out <= data_in;
                error <= 1'b0;
            end else begin
                data_out <= data_out; // Keep last valid
                error <= 1'b1;
            end
        end
    end
endmodule