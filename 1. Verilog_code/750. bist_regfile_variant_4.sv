//SystemVerilog
module bist_regfile #(
    parameter DW = 16,
    parameter AW = 4
)(
    input clk,
    input rst_n,
    input start_test,
    input normal_wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg test_done,
    output reg [7:0] error_count,
    output reg bist_active
);

parameter IDLE = 2'b00;
parameter WRITE_PATTERN = 2'b01;
parameter READ_VERIFY = 2'b10;
parameter REPAIR = 2'b11;

localparam PATTERN0 = 16'hAAAA;
localparam PATTERN1 = 16'h5555;

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW:0] test_addr_stage1, test_addr_stage2, test_addr_stage3;
reg [DW-1:0] expected_stage1, expected_stage2;
reg [1:0] state_stage1, state_stage2, state_stage3;
reg [DW-1:0] mem_data_stage1, mem_data_stage2;
reg valid_stage1, valid_stage2, valid_stage3;
integer i;

// Stage 1: Address Generation and Pattern Selection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1 <= IDLE;
        test_addr_stage1 <= 0;
        valid_stage1 <= 1'b0;
        expected_stage1 <= 0;
    end else begin
        case(state_stage1)
            IDLE: begin
                valid_stage1 <= 1'b0;
                if (start_test) begin
                    state_stage1 <= WRITE_PATTERN;
                    test_addr_stage1 <= 0;
                    valid_stage1 <= 1'b1;
                end
            end
            
            WRITE_PATTERN: begin
                expected_stage1 <= (test_addr_stage1[0]) ? PATTERN1 : PATTERN0;
                valid_stage1 <= 1'b1;
                if (test_addr_stage1 == (1<<AW)-1) begin
                    state_stage1 <= READ_VERIFY;
                    test_addr_stage1 <= 0;
                end else begin
                    test_addr_stage1 <= test_addr_stage1 + 1;
                end
            end
            
            READ_VERIFY: begin
                valid_stage1 <= 1'b1;
                if (test_addr_stage1 == (1<<AW)-1) begin
                    state_stage1 <= REPAIR;
                    test_addr_stage1 <= 0;
                end else begin
                    test_addr_stage1 <= test_addr_stage1 + 1;
                end
            end
            
            REPAIR: begin
                valid_stage1 <= 1'b1;
                if (test_addr_stage1 == (1<<AW)-1) begin
                    state_stage1 <= IDLE;
                end else begin
                    test_addr_stage1 <= test_addr_stage1 + 1;
                end
            end
            
            default: state_stage1 <= IDLE;
        endcase
    end
end

// Stage 2: Memory Access with Borrowing Subtractor
reg [DW-1:0] borrow_subtractor_result;
reg borrow_out;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2 <= IDLE;
        test_addr_stage2 <= 0;
        valid_stage2 <= 1'b0;
        mem_data_stage1 <= 0;
        expected_stage2 <= 0;
        borrow_out <= 0;
    end else begin
        state_stage2 <= state_stage1;
        test_addr_stage2 <= test_addr_stage1;
        valid_stage2 <= valid_stage1;
        expected_stage2 <= expected_stage1;
        
        if (normal_wr_en) begin
            mem[addr] <= din;
        end
        
        if (valid_stage1) begin
            case(state_stage1)
                WRITE_PATTERN: begin
                    mem[test_addr_stage1] <= expected_stage1;
                end
                READ_VERIFY: begin
                    mem_data_stage1 <= mem[test_addr_stage1];
                end
                REPAIR: begin
                    mem[test_addr_stage1] <= (test_addr_stage1[0]) ? PATTERN1 : PATTERN0;
                end
            endcase
        end
    end
end

// Borrowing Subtractor Logic
always @(*) begin
    borrow_subtractor_result = 0;
    borrow_out = 0;
    for (i = 0; i < 8; i = i + 1) begin
        if (mem_data_stage1[i] < expected_stage2[i] + borrow_out) begin
            borrow_subtractor_result[i] = mem_data_stage1[i] + 1'b1 - expected_stage2[i] - borrow_out;
            borrow_out = 1;
        end else begin
            borrow_subtractor_result[i] = mem_data_stage1[i] - expected_stage2[i] - borrow_out;
            borrow_out = 0;
        end
    end
end

// Stage 3: Error Detection and Output Generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage3 <= IDLE;
        test_addr_stage3 <= 0;
        valid_stage3 <= 1'b0;
        error_count <= 0;
        test_done <= 1'b1;
        bist_active <= 1'b0;
        dout <= 0;
    end else begin
        state_stage3 <= state_stage2;
        test_addr_stage3 <= test_addr_stage2;
        valid_stage3 <= valid_stage2;
        
        if (valid_stage2) begin
            case(state_stage2)
                READ_VERIFY: begin
                    if (borrow_subtractor_result != expected_stage2) begin
                        error_count <= error_count + 1;
                    end
                end
            endcase
        end
        
        test_done <= (state_stage3 == IDLE);
        bist_active <= (state_stage3 != IDLE);
        dout <= mem[addr];
    end
end

endmodule