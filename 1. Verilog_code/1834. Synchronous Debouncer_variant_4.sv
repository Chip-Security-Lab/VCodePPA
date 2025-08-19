//SystemVerilog
module rising_edge_detector #(parameter COUNT_LIMIT = 4) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire signal_in,
    output reg  edge_detected,
    output reg [$clog2(COUNT_LIMIT):0] edge_count
);
    reg signal_d1;
    reg signal_d2;
    wire edge_found;
    
    // Edge detection moved before the output register
    assign edge_found = signal_in & ~signal_d1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            signal_d1 <= 1'b0;
            signal_d2 <= 1'b0;
            edge_detected <= 1'b0;
            edge_count <= {$clog2(COUNT_LIMIT)+1{1'b0}};
        end else begin
            signal_d1 <= signal_in;
            signal_d2 <= signal_d1;
            
            // Register edge_found result rather than calculating it in the same cycle
            edge_detected <= edge_found;
            
            if (edge_found) begin
                edge_count <= (edge_count == COUNT_LIMIT) ? 
                              {$clog2(COUNT_LIMIT)+1{1'b0}} : edge_count + 1'b1;
            end
        end
    end
endmodule