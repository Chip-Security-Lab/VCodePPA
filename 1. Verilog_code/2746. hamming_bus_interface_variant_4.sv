//SystemVerilog
module hamming_bus_interface(
    input clk, rst, cs, we,
    input [3:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg req,
    input ack
);
    reg [6:0] encoded;
    reg [3:0] status;
    reg cs_prev;
    
    wire cs_rising_edge = cs && !cs_prev;
    wire operation_ready = req && ack && cs;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            status <= 4'b0;
            rdata <= 8'b0;
            req <= 1'b0;
            cs_prev <= 1'b0;
        end else begin
            cs_prev <= cs;
            
            // Simplified request logic
            if (cs_rising_edge)
                req <= 1'b1;
            else if (req && ack)
                req <= 1'b0;
            
            // Process data when request is acknowledged
            if (operation_ready) begin
                if (we) begin
                    if (addr == 4'h0) begin // Input data
                        // Optimized Hamming encoding with parallel assignments
                        encoded[2] <= wdata[0];
                        encoded[4] <= wdata[1];
                        encoded[5] <= wdata[2];
                        encoded[6] <= wdata[3];
                        encoded[0] <= wdata[0] ^ wdata[1] ^ wdata[3];
                        encoded[1] <= wdata[0] ^ wdata[2] ^ wdata[3];
                        encoded[3] <= wdata[1] ^ wdata[2] ^ wdata[3];
                        status[0] <= 1'b1; // Encoding done
                    end
                    else if (addr == 4'h4)
                        status <= wdata[3:0]; // Control register
                end else begin
                    // Optimized read logic using case equality operator
                    case (addr)
                        4'h0: rdata <= {1'b0, encoded}; // Read encoded data
                        4'h4: rdata <= {4'b0, status};  // Read status
                        default: rdata <= 8'b0;
                    endcase
                end
            end
        end
    end
endmodule