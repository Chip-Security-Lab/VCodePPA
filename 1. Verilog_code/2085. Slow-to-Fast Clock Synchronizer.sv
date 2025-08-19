module slow_to_fast_sync #(parameter WIDTH = 12) (
    input wire slow_clk, fast_clk, rst_n,
    input wire [WIDTH-1:0] slow_data,
    output reg [WIDTH-1:0] fast_data,
    output reg data_valid
);
    reg slow_toggle;
    reg [WIDTH-1:0] capture_data;
    reg [2:0] fast_sync;
    reg fast_toggle_prev;
    
    // Slow clock domain
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle <= 1'b0;
            capture_data <= {WIDTH{1'b0}};
        end else begin
            slow_toggle <= ~slow_toggle;
            capture_data <= slow_data;
        end
    end
    
    // Fast clock domain
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_sync <= 3'b0;
            fast_toggle_prev <= 1'b0;
            fast_data <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            fast_sync <= {fast_sync[1:0], slow_toggle};
            fast_toggle_prev <= fast_sync[2];
            
            data_valid <= 1'b0;
            if (fast_sync[2] != fast_toggle_prev) begin
                fast_data <= capture_data;
                data_valid <= 1'b1;
            end
        end
    end
endmodule