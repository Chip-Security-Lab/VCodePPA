//SystemVerilog
module split_rom (
    input clk,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [15:0] data
);
    reg [7:0] rom0 [0:15];
    reg [7:0] rom1 [0:15];
    
    // Pipeline stage 1 signals
    reg req_stage1;
    reg [3:0] addr_stage1;
    
    // Pipeline stage 2 signals
    reg req_stage2;
    reg [3:0] addr_stage2;
    reg [7:0] rom0_data_stage2;
    reg [7:0] rom1_data_stage2;
    
    // Pipeline stage 3 signals
    reg req_stage3;
    reg [15:0] data_stage3;

    initial begin
        rom0[0] = 8'h12; rom0[1] = 8'h34;
        rom1[0] = 8'hAB; rom1[1] = 8'hCD;
        ack = 1'b0;
        req_stage1 = 1'b0;
        req_stage2 = 1'b0;
        req_stage3 = 1'b0;
    end

    // Stage 1: Address and request capture
    always @(posedge clk) begin
        req_stage1 <= req;
        addr_stage1 <= addr;
    end

    // Stage 2: ROM data read
    always @(posedge clk) begin
        req_stage2 <= req_stage1;
        addr_stage2 <= addr_stage1;
        rom0_data_stage2 <= rom0[addr_stage1];
        rom1_data_stage2 <= rom1[addr_stage1];
    end

    // Stage 3: Data assembly and ack generation
    always @(posedge clk) begin
        req_stage3 <= req_stage2;
        if (req_stage2 && !req_stage3) begin
            data_stage3 <= {rom1_data_stage2, rom0_data_stage2};
            ack <= 1'b1;
        end else if (!req_stage2) begin
            ack <= 1'b0;
        end
        data <= data_stage3;
    end
endmodule