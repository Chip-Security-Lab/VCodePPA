//SystemVerilog
module TimeoutArbiter #(parameter T=10) (
    input clk, rst,
    input req,
    output reg grant
);

// Pipeline stage registers
reg [7:0] timeout_counter;
reg [7:0] timeout_next;
reg req_pipe;
reg grant_pipe;

// Timeout control logic
wire timeout_expired = (timeout_counter == 0);
wire timeout_active = (timeout_counter > 0);

// Request pipeline
always @(posedge clk) begin
    if(rst) begin
        timeout_counter <= 0;
        timeout_next <= 0;
        req_pipe <= 0;
        grant_pipe <= 0;
        grant <= 0;
    end else begin
        // Request pipeline stage
        req_pipe <= req;
        
        // Timeout counter update
        if(timeout_expired) begin
            timeout_counter <= (req_pipe) ? T : 0;
        end else begin
            timeout_counter <= timeout_counter - 1;
        end
        
        // Grant generation
        grant_pipe <= (timeout_expired) ? req_pipe : 0;
        
        // Output stage
        grant <= grant_pipe;
    end
end

endmodule