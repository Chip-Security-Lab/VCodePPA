//SystemVerilog
module hamming_bus_interface(
    input clk, rst, cs, we,
    input [3:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg ready
);
    reg [6:0] encoded;
    reg [3:0] status;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            status <= 4'b0;
            rdata <= 8'b0;
            ready <= 1'b0;
        end else if (cs) begin
            ready <= 1'b1;
            if (we) begin
                if (addr == 4'h0) begin // Input data
                    encoded[0] <= wdata[0] ^ wdata[1] ^ wdata[3];
                    encoded[1] <= wdata[0] ^ wdata[2] ^ wdata[3];
                    encoded[2] <= wdata[0];
                    encoded[3] <= wdata[1] ^ wdata[2] ^ wdata[3];
                    encoded[4] <= wdata[1];
                    encoded[5] <= wdata[2];
                    encoded[6] <= wdata[3];
                    status[0] <= 1'b1; // Encoding done
                end else if (addr == 4'h4) begin
                    status <= wdata[3:0]; // Control register
                end
            end else begin
                if (addr == 4'h0) begin
                    rdata <= {1'b0, encoded}; // Read encoded data
                end else if (addr == 4'h4) begin
                    rdata <= {4'b0, status}; // Read status
                end
            end
        end else begin
            ready <= 1'b0;
        end
    end
endmodule