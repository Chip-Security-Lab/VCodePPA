//SystemVerilog
module MatrixArbiter #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output [N-1:0] grant
);

// Buffered signals
reg [N-1:0] priority_matrix [0:N-1];
reg [N-1:0] priority_matrix_buf [0:N-1];
reg [1:0] counter;
reg [1:0] counter_buf;
reg [1:0] inv_counter;
reg [1:0] inv_counter_buf;
reg [1:0] sum;
reg [1:0] sum_buf;
reg [1:0] carry;
reg [1:0] carry_buf;
reg [1:0] counter_next;
reg [1:0] counter_next_buf;
reg [N-1:0] grant_buf;

integer i;

// Conditional inversion
always @(*) begin
    inv_counter[0] = counter[0] ^ 1'b1;
    inv_counter[1] = counter[1] ^ 1'b1;
end

// Half adder for LSB
always @(*) begin
    sum[0] = inv_counter[0] ^ 1'b1;
    carry[0] = inv_counter[0] & 1'b1;
end

// Full adder for MSB
always @(*) begin
    sum[1] = inv_counter[1] ^ carry[0];
    carry[1] = inv_counter[1] & carry[0];
end

// Next counter value
always @(*) begin
    counter_next = sum;
end

// Main sequential logic with buffering
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1) begin
            priority_matrix[i] <= 0;
            priority_matrix_buf[i] <= 0;
        end
        counter <= 0;
        counter_buf <= 0;
        inv_counter_buf <= 0;
        sum_buf <= 0;
        carry_buf <= 0;
        counter_next_buf <= 0;
        grant_buf <= 0;
    end else begin
        // Buffer priority matrix
        for(i=N-1; i>0; i=i-1) begin
            priority_matrix_buf[i] <= priority_matrix[i-1];
            priority_matrix[i] <= priority_matrix_buf[i];
        end
        priority_matrix_buf[0] <= req;
        priority_matrix[0] <= priority_matrix_buf[0];
        
        // Buffer counter and related signals
        counter_buf <= counter_next;
        counter <= counter_buf;
        inv_counter_buf <= inv_counter;
        sum_buf <= sum;
        carry_buf <= carry;
        counter_next_buf <= counter_next;
        
        // Buffer grant output
        grant_buf <= req & priority_matrix[counter];
    end
end

assign grant = grant_buf;

endmodule