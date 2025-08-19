//SystemVerilog
module sync_priority_comparator #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid
);
    // Stage 1 registers
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [$clog2(WIDTH)-1:0] priority_stage2;
    reg valid_stage2;
    
    // 查找表辅助优先级编码
    function [$clog2(WIDTH)-1:0] priority_encoder;
        input [WIDTH-1:0] data;
        reg [$clog2(WIDTH)-1:0] result;
        reg found;
    begin
        result = 0;
        found = 1'b0;
        
        case(data)
            8'b1???_????: begin result = 7; found = 1'b1; end
            8'b01??_????: begin result = 6; found = 1'b1; end
            8'b001?_????: begin result = 5; found = 1'b1; end
            8'b0001_????: begin result = 4; found = 1'b1; end
            8'b0000_1???: begin result = 3; found = 1'b1; end
            8'b0000_01??: begin result = 2; found = 1'b1; end
            8'b0000_001?: begin result = 1; found = 1'b1; end
            8'b0000_0001: begin result = 0; found = 1'b1; end
            default:      begin result = 0; found = 1'b0; end
        endcase
        
        priority_encoder = result;
    end
    endfunction
    
    // Stage 1: Input capturing and detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= |data_in;
        end
    end
    
    // Stage 2: Priority encoding using lookup table
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            priority_stage2 <= priority_encoder(data_stage1);
        end
    end
    
    // Output stage: Final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid <= 0;
        end else begin
            priority_out <= priority_stage2;
            valid <= valid_stage2;
        end
    end
endmodule