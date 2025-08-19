//SystemVerilog
module source_id_ismu(
    input wire clk, rst_n,
    input wire [7:0] irq,
    input wire ack,
    output reg [2:0] src_id,
    output reg valid
);
    reg [7:0] pending;
    
    // Pending register update logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pending <= 8'h0;
        end else begin
            // Set bits based on IRQ
            pending <= pending | irq;
            
            // Clear bit based on acknowledgment
            if (ack)
                pending[src_id] <= 1'b0;
        end
    end
    
    // Priority encoder logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            src_id <= 3'h0;
        end else if (pending != 8'h0) begin
            // Structured priority encoding using if-else
            if (pending[0])
                src_id <= 3'd0;
            else if (pending[1])
                src_id <= 3'd1;
            else if (pending[2])
                src_id <= 3'd2;
            else if (pending[3])
                src_id <= 3'd3;
            else if (pending[4])
                src_id <= 3'd4;
            else if (pending[5])
                src_id <= 3'd5;
            else if (pending[6])
                src_id <= 3'd6;
            else if (pending[7])
                src_id <= 3'd7;
        end
    end
    
    // Valid signal generation
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid <= 1'b0;
        end else begin
            // Simple condition for valid signal
            valid <= (pending != 8'h0);
        end
    end
endmodule