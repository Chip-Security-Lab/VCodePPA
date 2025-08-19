//SystemVerilog
module updown_load_counter (
    input wire clk, rst_n, load, up_down,
    input wire [7:0] data_in,
    output wire [7:0] q
);
    reg [7:0] q_reg;
    
    // Combined input registration and counter logic to reduce register count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= 8'h00;
        end else begin
            // Priority logic optimized for synthesis
            case (1'b1)
                load:    q_reg <= data_in;
                up_down: q_reg <= q_reg + 1'b1;
                default: q_reg <= q_reg - 1'b1;
            endcase
        end
    end
    
    // Direct assignment to output
    assign q = q_reg;
endmodule