//SystemVerilog
module sync_hamming_decoder(
    input clk,
    input rst_n,
    
    // Input interface
    input [11:0] encoded_in,
    input valid_in,
    output ready_out,
    
    // Output interface
    output reg [7:0] data_out,
    output reg single_err,
    output reg double_err,
    output valid_out,
    input ready_in
);
    // Internal signals
    wire [3:0] syndrome;
    wire parity_check;
    wire [7:0] decoded_data;
    wire single_error, double_error;
    
    // Handshake control
    reg busy;
    
    // Calculate syndrome and error detection (combinational)
    assign syndrome[0] = encoded_in[0] ^ encoded_in[2] ^ encoded_in[4] ^ encoded_in[6] ^ encoded_in[8] ^ encoded_in[10];
    assign syndrome[1] = encoded_in[1] ^ encoded_in[2] ^ encoded_in[5] ^ encoded_in[6] ^ encoded_in[9] ^ encoded_in[10];
    assign syndrome[2] = encoded_in[3] ^ encoded_in[4] ^ encoded_in[5] ^ encoded_in[6];
    assign syndrome[3] = encoded_in[7] ^ encoded_in[8] ^ encoded_in[9] ^ encoded_in[10];
    assign parity_check = ^encoded_in;
    assign single_error = |syndrome & ~parity_check;
    assign double_error = |syndrome & parity_check;
    assign decoded_data = {encoded_in[10:7], encoded_in[6:4], encoded_in[2]};
    
    // Handshake logic
    assign ready_out = !busy;
    assign valid_out = busy;
    
    // Processing and output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            data_out <= 8'b0;
            single_err <= 1'b0;
            double_err <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                // Accept new data
                busy <= 1'b1;
                data_out <= decoded_data;
                single_err <= single_error;
                double_err <= double_error;
            end else if (busy && ready_in) begin
                // Data consumed by downstream logic
                busy <= 1'b0;
            end
        end
    end
endmodule