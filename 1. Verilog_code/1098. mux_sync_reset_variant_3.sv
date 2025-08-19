//SystemVerilog
module mux_valid_ready (
    input wire clk,                        // Clock input
    input wire rst,                        // Synchronous reset
    input wire [7:0] data_in_0,            // Data input 0
    input wire [7:0] data_in_1,            // Data input 1
    input wire sel,                        // Selection input
    input wire data_valid,                 // Input data valid
    output wire data_ready,                // Input data ready
    output reg [7:0] data_out,             // Output data
    output reg data_out_valid,             // Output data valid
    input wire data_out_ready              // Output data ready (from downstream)
);

    reg [7:0] data_selected;
    reg data_selected_valid;

    assign data_ready = (rst) ? 1'b0 : (data_out_ready);

    always @(posedge clk) begin
        if (rst) begin
            data_selected <= 8'b0;
            data_selected_valid <= 1'b0;
        end else begin
            if (data_valid && data_ready) begin
                data_selected <= sel ? data_in_1 : data_in_0;
                data_selected_valid <= 1'b1;
            end else if (data_out_ready && data_out_valid) begin
                data_selected_valid <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
            data_out_valid <= 1'b0;
        end else begin
            if (data_selected_valid && data_out_ready) begin
                data_out <= data_selected;
                data_out_valid <= 1'b1;
            end else if (data_out_ready && data_out_valid) begin
                data_out_valid <= 1'b0;
            end
        end
    end

endmodule