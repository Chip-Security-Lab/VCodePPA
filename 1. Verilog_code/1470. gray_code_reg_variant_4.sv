//SystemVerilog
module gray_code_reg(
    input clk, reset,
    input [7:0] bin_in,
    input req_load, req_convert,  // Request signals (replacing load, convert)
    output reg ack_load, ack_convert,  // Acknowledge signals (replacing ready)
    output reg [7:0] gray_out
);
    reg [7:0] binary;
    reg load_done, convert_done;

    // Handshake logic for load operation
    always @(posedge clk) begin
        if (reset) begin
            ack_load <= 1'b0;
            load_done <= 1'b0;
        end else if (req_load && !load_done) begin
            binary <= bin_in;
            ack_load <= 1'b1;
            load_done <= 1'b1;
        end else if (!req_load && load_done) begin
            ack_load <= 1'b0;
            load_done <= 1'b0;
        end
    end

    // Handshake logic for convert operation
    always @(posedge clk) begin
        if (reset) begin
            gray_out <= 8'h00;
            ack_convert <= 1'b0;
            convert_done <= 1'b0;
        end else if (req_convert && !convert_done) begin
            gray_out <= binary ^ {1'b0, binary[7:1]};
            ack_convert <= 1'b1;
            convert_done <= 1'b1;
        end else if (!req_convert && convert_done) begin
            ack_convert <= 1'b0;
            convert_done <= 1'b0;
        end
    end
endmodule