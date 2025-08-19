//SystemVerilog
module del_pulse_div #(
    parameter N = 3  // Configurable division factor
) (
    input  wire clk,     // Input clock signal
    input  wire rst,     // Active high reset
    output reg  clk_out  // Output divided clock signal
);

    // Optimized counter width based on parameter N
    localparam CNT_WIDTH = $clog2(N);
    
    // Pipeline stage 1: Counter registers with optimized width
    reg [CNT_WIDTH-1:0] cnt_r;  // Counter register with optimized width
    reg                 cnt_max_r;  // Counter maximum value flag

    // Pipeline stage 2: Clock toggle control
    reg                 toggle_en_r;  // Enable signal for clock toggling
    
    // Counter logic - First pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_r <= {CNT_WIDTH{1'b0}};
            cnt_max_r <= 1'b0;
        end else begin
            // Determine if counter reached maximum value (optimized comparison)
            cnt_max_r <= (cnt_r == (N-2));
            
            // Counter update logic with optimized reset condition
            if (cnt_r >= (N-1)) begin  // Using >= for better timing
                cnt_r <= {CNT_WIDTH{1'b0}};
            end else begin
                cnt_r <= cnt_r + 1'b1;
            end
        end
    end
    
    // Toggle enable logic - Intermediate stage with optimized comparison
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            toggle_en_r <= 1'b0;
        end else begin
            toggle_en_r <= (cnt_r >= (N-1));  // Using >= for better timing
        end
    end
    
    // Clock output generation - Final stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (toggle_en_r) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule