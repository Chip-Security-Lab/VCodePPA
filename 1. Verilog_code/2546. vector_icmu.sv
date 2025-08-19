module vector_icmu (
    input clk, rst_b,
    input [31:0] int_vector,
    input enable,
    input [63:0] current_context,
    output reg int_active,
    output reg [63:0] saved_context,
    output reg [4:0] vector_number
);
    reg [31:0] pending, masked;
    reg [31:0] mask;
    
    // 初始化mask
    initial begin
        mask = 32'hFFFFFFFF;
    end
    
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pending <= 32'h0;
            int_active <= 1'b0;
            saved_context <= 64'h0;
            vector_number <= 5'h0;
            mask <= 32'hFFFFFFFF;
        end else begin
            // Latch new interrupts
            pending <= pending | int_vector;
            masked <= pending & mask & {32{enable}};
            
            // Handle next interrupt
            if (!int_active && |masked) begin
                vector_number <= priority_encoder(masked);
                saved_context <= current_context;
                int_active <= 1'b1;
                pending <= pending & ~(32'h1 << vector_number);
            end
        end
    end
    
    // 修改函数实现
    function [4:0] priority_encoder;
        input [31:0] vector;
        reg [4:0] result;
        integer i;
        begin
            result = 5'h0;
            for (i = 31; i >= 0; i = i - 1)
                if (vector[i]) result = i[4:0];
            priority_encoder = result;
        end
    endfunction
endmodule