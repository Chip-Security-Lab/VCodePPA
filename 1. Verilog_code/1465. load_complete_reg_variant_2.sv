//SystemVerilog
module load_complete_reg(
    input wire clk, rst,
    input wire [15:0] data_in,
    input wire req,
    output reg [15:0] data_out,
    output reg ack
);

    // IEEE 1364-2005 Verilog standard
    
    reg req_r;
    wire req_edge_rising, req_edge_falling;
    
    // Optimize edge detection with dedicated signals
    assign req_edge_rising = req & ~req_r;
    assign req_edge_falling = ~req & req_r;

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
            ack <= 1'b0;
            req_r <= 1'b0;
        end else begin
            req_r <= req;
            
            // Use pre-computed edge detection signals
            if (req_edge_rising) begin
                data_out <= data_in;
                ack <= 1'b1;
            end else if (req_edge_falling) begin
                ack <= 1'b0;
            end
        end
    end
endmodule