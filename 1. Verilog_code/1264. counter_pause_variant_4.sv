//SystemVerilog
module counter_pause #(parameter WIDTH=4) (
    input clk, rst, pause,
    output reg [WIDTH-1:0] cnt
);
    // Register for pause signal to reduce input-to-register delay
    reg pause_reg;
    
    // Single always block for all registers with the same clock domain
    always @(posedge clk) begin
        if (rst) begin
            pause_reg <= 1'b0;
            cnt <= {WIDTH{1'b0}};
        end
        else begin
            pause_reg <= pause;
            // Counter logic directly integrated into always block
            if (pause_reg)
                cnt <= cnt; // Hold value when paused
            else
                cnt <= cnt + 1'b1; // Increment when not paused
        end
    end
endmodule