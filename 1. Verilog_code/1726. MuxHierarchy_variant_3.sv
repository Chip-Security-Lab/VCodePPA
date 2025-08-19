//SystemVerilog
module MuxHierarchy #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    output reg [W-1:0] data
);

// Intermediate signals for pipelining
reg [W-1:0] selected_group;
reg [W-1:0] final_output;

// Stage 1: Select group based on the highest address bit
always @(*) begin
    if (addr[2]) begin
        selected_group = group[7:4];
    end else begin
        selected_group = group[3:0];
    end
end

// Stage 2: Select final output based on the lower address bits
always @(*) begin
    if (addr[1:0] == 2'b00) begin
        final_output = selected_group[0];
    end else if (addr[1:0] == 2'b01) begin
        final_output = selected_group[1];
    end else if (addr[1:0] == 2'b10) begin
        final_output = selected_group[2];
    end else begin
        final_output = selected_group[3];
    end
end

// Final output assignment
always @(*) begin
    data = final_output;
end

endmodule