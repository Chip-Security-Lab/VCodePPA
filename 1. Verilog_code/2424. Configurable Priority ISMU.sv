module config_priority_ismu #(parameter N_SRC = 8)(
    input wire clock, resetn,
    input wire [N_SRC-1:0] interrupt_in,
    input wire [N_SRC-1:0] interrupt_mask,
    input wire [3*N_SRC-1:0] priority_config,
    output reg [2:0] highest_priority,
    output reg interrupt_valid
);
    reg [2:0] curr_priority [N_SRC-1:0];
    reg [2:0] max_priority;
    integer i;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            interrupt_valid <= 1'b0;
            highest_priority <= 3'd0;
        end else begin
            max_priority = 0;
            interrupt_valid <= 1'b0;
            for (i = 0; i < N_SRC; i = i + 1) begin
                curr_priority[i] = priority_config[i*3+:3];
                if (interrupt_in[i] && !interrupt_mask[i] && 
                    curr_priority[i] > max_priority) begin
                    max_priority = curr_priority[i];
                    highest_priority <= i[2:0];
                    interrupt_valid <= 1'b1;
                end
            end
        end
    end
endmodule