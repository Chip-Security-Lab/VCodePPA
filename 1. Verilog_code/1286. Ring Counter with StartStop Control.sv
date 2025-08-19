module controlled_ring_counter(
    input wire clock,
    input wire reset,
    input wire run, // Start/stop control
    output reg [3:0] state
);
    reg running;
    
    always @(posedge clock) begin
        if (reset) begin
            state <= 4'b0001;
            running <= 0;
        end
        else begin
            if (run)
                running <= 1;
            else if (!run)
                running <= 0;
                
            if (running)
                state <= {state[2:0], state[3]};
        end
    end
endmodule