module rising_edge_detector #(parameter COUNT_LIMIT = 4) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire signal_in,
    output reg  edge_detected,
    output reg [$clog2(COUNT_LIMIT):0] edge_count
);
    reg signal_d1;
    wire edge_found;
    
    assign edge_found = signal_in & ~signal_d1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            signal_d1 <= 1'b0;
            edge_detected <= 1'b0;
            edge_count <= {$clog2(COUNT_LIMIT)+1{1'b0}};
        end else begin
            signal_d1 <= signal_in;
            edge_detected <= edge_found;
            
            if (edge_found) begin
                edge_count <= (edge_count == COUNT_LIMIT) ? 
                              {$clog2(COUNT_LIMIT)+1{1'b0}} : edge_count + 1'b1;
            end
        end
    end
endmodule