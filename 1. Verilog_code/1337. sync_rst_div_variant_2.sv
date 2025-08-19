//SystemVerilog
// SystemVerilog
module sync_rst_div #(
    parameter DIV = 8
) (
    input  wire clk,
    input  wire async_rst,
    output reg  clk_out
);
    // Optimized reset synchronization using a shift register
    reg [2:0] rst_sync_sr;
    
    // Count register with width determined by DIV parameter
    localparam CNT_WIDTH = $clog2(DIV/2);
    reg [CNT_WIDTH-1:0] cnt;
    
    // Reset synchronization logic - combined into a single shift register
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            rst_sync_sr <= 3'b111;
        else
            rst_sync_sr <= {rst_sync_sr[1:0], 1'b0};
    end
    
    // Integrated counter and clock output generation
    wire cnt_terminal = (cnt == (DIV/2-1));
    
    always @(posedge clk) begin
        if (rst_sync_sr[2]) begin
            cnt <= {CNT_WIDTH{1'b0}};
            clk_out <= 1'b0;
        end
        else begin
            cnt <= cnt_terminal ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
            
            if (cnt_terminal)
                clk_out <= ~clk_out;
        end
    end
endmodule