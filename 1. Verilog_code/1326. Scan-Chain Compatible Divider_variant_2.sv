//SystemVerilog
module scan_divider (
    input clk, rst_n, req, scan_in,
    output reg clk_div,
    output ack,
    output scan_out
);
    reg [2:0] counter;
    reg scan_in_reg;
    reg req_state;
    
    // Register the scan_in input to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_in_reg <= 1'b0;
        end else begin
            scan_in_reg <= scan_in;
        end
    end
    
    // Track request state for handshake implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_state <= 1'b0;
        end else if (req && !req_state) begin
            req_state <= 1'b1;
        end else if (!req && req_state) begin
            req_state <= 1'b0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'b000;
            clk_div <= 1'b0;
        end else if (req_state) begin
            counter <= {counter[1:0], scan_in_reg}; // Use registered scan_in
        end else if (counter == 3'b111) begin
            counter <= 3'b000;
            clk_div <= ~clk_div;
        end else
            counter <= counter + 1'b1;
    end
    
    // Generate acknowledge signal when request is processed
    assign ack = req_state;
    assign scan_out = counter[2];
endmodule